#import "SpatialVideoDecoder.h"
#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR
#import <Metal/Metal.h>
#import <MetalFX/MetalFX.h>
#import <VideoToolbox/VideoToolbox.h>

@interface SpatialVideoDecoder ()
@property (atomic, readwrite) BOOL failed;
@property (atomic) BOOL stopped;
@end

@implementation SpatialVideoDecoder {
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLFXSpatialScaler> _scaler;
    id<MTLTexture> _upscaledTexture;
    CVMetalTextureCacheRef _textureCache;
    CVPixelBufferPoolRef _outputPool;
    VTDecompressionSessionRef _session;
    dispatch_queue_t _renderQueue;
    dispatch_semaphore_t _availableFrames;
    CGSize _outputSize;
    void (^_frameHandler)(CVPixelBufferRef);
}

+ (BOOL)isSupported {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    return device != nil && [MTLFXSpatialScalerDescriptor supportsDevice:device];
}

- (instancetype)initWithOutputSize:(CGSize)size frameHandler:(void (^)(CVPixelBufferRef))handler {
    self = [super init];
    if (!self) return nil;
    _device = MTLCreateSystemDefaultDevice();
    if (!_device || ![MTLFXSpatialScalerDescriptor supportsDevice:_device] ||
        size.width < 2 || size.height < 2) return nil;
    _commandQueue = [_device newCommandQueue];
    if (!_commandQueue || CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, _device, NULL, &_textureCache) != kCVReturnSuccess) return nil;
    _outputSize = size;
    // MetalFX requires private output storage. A GPU blit below transfers the
    // result into the IOSurface-backed buffer consumed by the display layer.
    MTLTextureDescriptor *texture = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
        width:(NSUInteger)size.width height:(NSUInteger)size.height mipmapped:NO];
    texture.storageMode = MTLStorageModePrivate;
    texture.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
    _upscaledTexture = [_device newTextureWithDescriptor:texture];
    if (!_upscaledTexture) return nil;
    _frameHandler = [handler copy];
    _renderQueue = dispatch_queue_create("Astralight.MetalFX", DISPATCH_QUEUE_SERIAL);
    // Include GPU execution and main-queue delivery in the limit. Overload drops
    // presentation frames without skipping decode reference frames or building latency.
    _availableFrames = dispatch_semaphore_create(2);
    NSDictionary *attributes = @{
        (id)kCVPixelBufferWidthKey: @((NSUInteger)size.width),
        (id)kCVPixelBufferHeightKey: @((NSUInteger)size.height),
        (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
        (id)kCVPixelBufferMetalCompatibilityKey: @YES,
        (id)kCVPixelBufferIOSurfacePropertiesKey: @{}
    };
    if (CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (__bridge CFDictionaryRef)attributes, &_outputPool) != kCVReturnSuccess) return nil;
    return self;
}

- (void)fail:(NSString *)reason {
    if (!self.failed && !self.stopped) NSLog(@"Astralight MetalFX fallback: %@", reason);
    self.failed = YES;
}

- (BOOL)decodeSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    NSAssert(NSThread.isMainThread, @"Decode submission must run on the main queue");
    if (self.stopped || self.failed) return NO;
    CMVideoFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
    if (_session && !VTDecompressionSessionCanAcceptFormatDescription(_session, format)) {
        VTDecompressionSessionWaitForAsynchronousFrames(_session);
        VTDecompressionSessionInvalidate(_session);
        CFRelease(_session);
        _session = NULL;
    }
    if (!_session) {
        NSDictionary *decoder = @{
#if TARGET_OS_SIMULATOR
            (id)kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder: @YES
#else
            (id)kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder: @YES
#endif
        };
        NSDictionary *attributes = @{
            (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
            (id)kCVPixelBufferMetalCompatibilityKey: @YES,
            (id)kCVPixelBufferIOSurfacePropertiesKey: @{}
        };
        OSStatus status = VTDecompressionSessionCreate(kCFAllocatorDefault, format,
            (__bridge CFDictionaryRef)decoder, (__bridge CFDictionaryRef)attributes, NULL, &_session);
        if (status != noErr) {
            [self fail:[NSString stringWithFormat:@"decoder creation failed (%d)", (int)status]];
            return NO;
        }
        VTSessionSetProperty(_session, kVTDecompressionPropertyKey_RealTime, kCFBooleanTrue);
    }
    __weak SpatialVideoDecoder *weakSelf = self;
    OSStatus status = VTDecompressionSessionDecodeFrameWithOutputHandler(_session, sampleBuffer,
        kVTDecodeFrame_EnableAsynchronousDecompression, NULL,
        ^(OSStatus decodeStatus, VTDecodeInfoFlags flags, CVImageBufferRef image, CMTime pts, CMTime duration) {
            SpatialVideoDecoder *strongSelf = weakSelf;
            if (!strongSelf || strongSelf.stopped) return;
            if (decodeStatus != noErr) {
                [strongSelf fail:[NSString stringWithFormat:@"decode failed (%d)", (int)decodeStatus]];
                return;
            }
            if (!image || (flags & kVTDecodeInfo_FrameDropped)) return;
            [strongSelf queueImage:image];
        });
    if (status != noErr) [self fail:[NSString stringWithFormat:@"decode submission failed (%d)", (int)status]];
    return !self.failed;
}

- (void)queueImage:(CVPixelBufferRef)image {
    if (self.stopped || self.failed || dispatch_semaphore_wait(_availableFrames, DISPATCH_TIME_NOW) != 0) return;
    CVPixelBufferRetain(image);
    dispatch_async(_renderQueue, ^{
        @autoreleasepool {
            [self scaleImage:image];
            CVPixelBufferRelease(image);
        }
    });
}

- (void)scaleImage:(CVPixelBufferRef)image {
    if (self.stopped || self.failed) {
        dispatch_semaphore_signal(_availableFrames);
        return;
    }
    NSUInteger width = CVPixelBufferGetWidth(image), height = CVPixelBufferGetHeight(image);
    if (!_scaler || _scaler.inputWidth != width || _scaler.inputHeight != height) {
        MTLFXSpatialScalerDescriptor *descriptor = [[MTLFXSpatialScalerDescriptor alloc] init];
        descriptor.inputWidth = width;
        descriptor.inputHeight = height;
        descriptor.outputWidth = (NSUInteger)_outputSize.width;
        descriptor.outputHeight = (NSUInteger)_outputSize.height;
        descriptor.colorTextureFormat = MTLPixelFormatBGRA8Unorm;
        descriptor.outputTextureFormat = MTLPixelFormatBGRA8Unorm;
        descriptor.colorProcessingMode = MTLFXSpatialScalerColorProcessingModePerceptual;
        _scaler = [descriptor newSpatialScalerWithDevice:_device];
        if (!_scaler) {
            [self fail:@"scaler creation failed"];
            dispatch_semaphore_signal(_availableFrames);
            return;
        }
    }
    CVPixelBufferRef output = NULL;
    // The display layer may retain recent frames. Keep the pool bounded as well.
    NSDictionary *poolOptions = @{(id)kCVPixelBufferPoolAllocationThresholdKey: @5};
    CVReturn result = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, _outputPool,
        (__bridge CFDictionaryRef)poolOptions, &output);
    if (result != kCVReturnSuccess) {
        if (result != kCVReturnWouldExceedAllocationThreshold) [self fail:@"output buffer allocation failed"];
        dispatch_semaphore_signal(_availableFrames);
        return;
    }
    CVMetalTextureRef inputTexture = NULL, outputTexture = NULL;
    NSDictionary *inputUsage = @{(id)kCVMetalTextureUsage: @(_scaler.colorTextureUsage)};
    NSDictionary *outputUsage = @{(id)kCVMetalTextureUsage: @(MTLTextureUsageShaderRead)};
    result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, image,
        (__bridge CFDictionaryRef)inputUsage, MTLPixelFormatBGRA8Unorm, width, height, 0, &inputTexture);
    if (result == kCVReturnSuccess) {
        result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, output,
            (__bridge CFDictionaryRef)outputUsage, MTLPixelFormatBGRA8Unorm,
            (NSUInteger)_outputSize.width, (NSUInteger)_outputSize.height, 0, &outputTexture);
    }
    id<MTLCommandBuffer> command = [_commandQueue commandBuffer];
    if (result != kCVReturnSuccess || !command) {
        if (inputTexture) CFRelease(inputTexture);
        if (outputTexture) CFRelease(outputTexture);
        CVPixelBufferRelease(output);
        [self fail:@"Metal texture allocation failed"];
        dispatch_semaphore_signal(_availableFrames);
        return;
    }
    _scaler.colorTexture = CVMetalTextureGetTexture(inputTexture);
    _scaler.inputContentWidth = width;
    _scaler.inputContentHeight = height;
    _scaler.outputTexture = _upscaledTexture;
    [_scaler encodeToCommandBuffer:command];
    id<MTLBlitCommandEncoder> blit = [command blitCommandEncoder];
    [blit copyFromTexture:_upscaledTexture toTexture:CVMetalTextureGetTexture(outputTexture)];
    [blit endEncoding];
    // Keep the IOSurfaces and CVMetalTexture wrappers alive until the GPU is done.
    CVPixelBufferRetain(image);
    [command addCompletedHandler:^(id<MTLCommandBuffer> completed) {
        CFRelease(inputTexture);
        CFRelease(outputTexture);
        CVPixelBufferRelease(image);
        if (completed.status == MTLCommandBufferStatusError) [self fail:completed.error.localizedDescription];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.stopped && !self.failed) {
                CVBufferSetAttachment(output, kCVImageBufferColorPrimariesKey, kCVImageBufferColorPrimaries_ITU_R_709_2, kCVAttachmentMode_ShouldPropagate);
                CVBufferSetAttachment(output, kCVImageBufferTransferFunctionKey, kCVImageBufferTransferFunction_sRGB, kCVAttachmentMode_ShouldPropagate);
                self->_frameHandler(output);
            }
            CVPixelBufferRelease(output);
            dispatch_semaphore_signal(self->_availableFrames);
        });
    }];
    [command commit];
}

- (void)invalidate {
    self.stopped = YES;
    if (_session) {
        VTDecompressionSessionInvalidate(_session);
        CFRelease(_session);
        _session = NULL;
    }
}

- (void)dealloc {
    [self invalidate];
    if (_textureCache) CFRelease(_textureCache);
    if (_outputPool) CVPixelBufferPoolRelease(_outputPool);
}
@end

#else
// Apple does not ship MetalFX in the iOS Simulator SDK. Keep the native path
// available and disable the performance option there instead of pretending to scale.
@implementation SpatialVideoDecoder
+ (BOOL)isSupported { return NO; }
- (instancetype)initWithOutputSize:(CGSize)size frameHandler:(void (^)(CVPixelBufferRef))handler { return nil; }
- (BOOL)failed { return YES; }
- (BOOL)decodeSampleBuffer:(CMSampleBufferRef)sampleBuffer { return NO; }
- (void)invalidate {}
@end
#endif
