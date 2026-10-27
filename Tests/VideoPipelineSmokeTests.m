// Define ASTRALIGHT_EMBED_VIDEO_TESTS to include this diagnostic in Debug iOS builds only.
#if !defined(ASTRALIGHT_EMBED_VIDEO_TESTS) || DEBUG
// Standalone macOS GPU smoke test for the same decoder/scaler compiled into iOS.
// No host PC, network access, pairing changes, or game launch is required.
#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "SpatialVideoDecoder.h"
#import "StreamResolution.h"
#import "AV1TestFixtures.h"
#if defined(ASTRALIGHT_EMBED_VIDEO_TESTS)
#import "Utils.h"
#import "VideoDecoderRenderer.h"
// Exercise the same AV1 sequence-header parser used for live streaming.
@interface VideoDecoderRenderer (AV1SmokeTest)
- (CMVideoFormatDescriptionRef)createAV1FormatDescriptionForIDRFrame:(NSData *)frameData CF_RETURNS_RETAINED;
@end
#endif

static void Check(BOOL condition, NSString *message) {
    if (!condition) { NSLog(@"FAIL: %@", message); exit(1); }
}

static void OnMain(void (^block)(void)) {
    if (NSThread.isMainThread) block();
    else dispatch_sync(dispatch_get_main_queue(), block);
}

static void WaitBriefly(NSTimeInterval seconds) {
    if (NSThread.isMainThread) [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];
    else [NSThread sleepForTimeInterval:seconds];
}

static void EncodeCallback(void *context, void *source, OSStatus status, VTEncodeInfoFlags flags, CMSampleBufferRef sample) {
    Check(status == noErr && sample != NULL, @"test frame encoding");
    [(__bridge NSMutableArray *)context addObject:(__bridge id)sample];
}

static CMSampleBufferRef CreateFrame(int width, int height, CMVideoCodecType codec) CF_RETURNS_RETAINED;
static CMSampleBufferRef CreateFrame(int width, int height, CMVideoCodecType codec) {
    NSMutableArray *samples = [NSMutableArray array];
    VTCompressionSessionRef encoder = NULL;
    OSStatus status = VTCompressionSessionCreate(kCFAllocatorDefault, width, height, codec,
        NULL, NULL, NULL, EncodeCallback, (__bridge void *)samples, &encoder);
    Check(status == noErr, @"create encoder");
    VTSessionSetProperty(encoder, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    VTSessionSetProperty(encoder, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
    CVPixelBufferRef image = NULL;
    Check(CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, NULL, &image) == kCVReturnSuccess, @"allocate pattern");
    CVPixelBufferLockBaseAddress(image, 0);
    unsigned char *bytes = CVPixelBufferGetBaseAddress(image);
    size_t stride = CVPixelBufferGetBytesPerRow(image);
    for (int y = 0; y < height; y++) for (int x = 0; x < width; x++) {
        unsigned char *pixel = bytes + y * stride + x * 4;
        pixel[0] = x < width / 2 ? 0 : 255;
        pixel[1] = 0;
        pixel[2] = x < width / 2 ? 255 : 0;
        pixel[3] = 255;
    }
    CVPixelBufferUnlockBaseAddress(image, 0);
    status = VTCompressionSessionEncodeFrame(encoder, image, kCMTimeZero, CMTimeMake(1, 60), NULL, NULL, NULL);
    Check(status == noErr, @"encode pattern");
    VTCompressionSessionCompleteFrames(encoder, kCMTimeInvalid);
    Check(samples.count == 1, @"one encoded frame");
    CMSampleBufferRef sample = (CMSampleBufferRef)CFRetain((__bridge CFTypeRef)samples.firstObject);
    CVPixelBufferRelease(image);
    VTCompressionSessionInvalidate(encoder);
    CFRelease(encoder);
    return sample;
}

static NSArray *CreateAV1Samples(const ALAV1Fixture *fixture) {
    CMVideoFormatDescriptionRef format = NULL;
#if defined(ASTRALIGHT_EMBED_VIDEO_TESTS)
    VideoDecoderRenderer *parser = [VideoDecoderRenderer new];
    NSData *keyframe = [NSData dataWithBytes:fixture->data length:fixture->lengths[0]];
    format = [parser createAV1FormatDescriptionForIDRFrame:keyframe];
#else
    // The standalone Mac test has no UIKit renderer. Use the fixture's av1C
    // record; the iPhone test above additionally verifies the production parser.
    NSDictionary *extensions = @{
        (id)kCMFormatDescriptionExtension_SampleDescriptionExtensionAtoms: @{
            @"av1C": [NSData dataWithBytes:fixture->configuration length:fixture->configurationSize]
        },
        (id)kCMFormatDescriptionExtension_ColorPrimaries: (id)kCMFormatDescriptionColorPrimaries_ITU_R_709_2,
        (id)kCMFormatDescriptionExtension_TransferFunction: (id)kCMFormatDescriptionTransferFunction_ITU_R_709_2,
        (id)kCMFormatDescriptionExtension_YCbCrMatrix: (id)kCMFormatDescriptionYCbCrMatrix_ITU_R_709_2,
        (id)kCMFormatDescriptionExtension_FullRangeVideo: @NO,
        @"BitsPerComponent": @8
    };
    Check(CMVideoFormatDescriptionCreate(kCFAllocatorDefault, kCMVideoCodecType_AV1,
        fixture->width, fixture->height, (__bridge CFDictionaryRef)extensions, &format) == noErr, @"create AV1 format");
#endif
    Check(format != NULL, @"parse AV1 keyframe format");
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(format);
    Check(dimensions.width == fixture->width && dimensions.height == fixture->height, @"AV1 coded dimensions");
    NSMutableArray *samples = [NSMutableArray array];
    size_t offset = 0;
    for (size_t frame = 0; frame < fixture->frameCount; frame++) {
        size_t length = fixture->lengths[frame];
        CMBlockBufferRef data = NULL;
        Check(CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, NULL, length,
            kCFAllocatorDefault, NULL, 0, length, 0, &data) == noErr, @"allocate AV1 packet");
        Check(CMBlockBufferReplaceDataBytes(fixture->data + offset, data, 0, length) == noErr, @"copy AV1 packet");
        CMSampleTimingInfo timing = {CMTimeMake(1, 60), CMTimeMake(frame, 60), kCMTimeInvalid};
        CMSampleBufferRef sample = NULL;
        Check(CMSampleBufferCreateReady(kCFAllocatorDefault, data, format, 1, 1, &timing,
            1, &length, &sample) == noErr, @"create compressed AV1 sample");
        [samples addObject:(__bridge id)sample];
        CFRelease(sample);
        CFRelease(data);
        offset += length;
    }
    CFRelease(format);
    return samples;
}

int ALRunVideoSmokeTests(void) {
    @autoreleasepool {
        Check(CGSizeEqualToSize(ALStreamSizeForNativeSize(CGSizeMake(2880, 1980), false), CGSizeMake(2880, 1980)), @"native resolution remains native");
        Check(CGSizeEqualToSize(ALStreamSizeForNativeSize(CGSizeMake(2880, 1980), true), CGSizeMake(1440, 990)), @"half-size performance input");
        CGSize odd = ALStreamSizeForNativeSize(CGSizeMake(2796, 1290), true);
        Check((int)odd.width % 2 == 0 && (int)odd.height % 2 == 0, @"even chroma dimensions");
        Check(fabs(odd.width * 2 - 2796) <= 2 && fabs(odd.height * 2 - 1290) <= 2, @"only chroma alignment rounding");
        if (![SpatialVideoDecoder isSupported]) {
            NSLog(@"PASS: resolution alignment. SKIP: MetalFX unavailable on this device/runtime.");
            return 0;
        }
#if defined(ASTRALIGHT_EMBED_VIDEO_TESTS)
        __block CGSize outputSize;
        OnMain(^{ outputSize = [Utils nativeDisplaySizeForView:nil]; });
#else
        CGSize outputSize = CGSizeMake(1280, 720);
#endif
        NSLog(@"Testing MetalFX output at %.0f × %.0f", outputSize.width, outputSize.height);
        __block int delivered = 0;
        __block int av1FrameIndex = -1;
        __block CGSize av1InputSize = CGSizeZero;
        SpatialVideoDecoder *decoder = [[SpatialVideoDecoder alloc] initWithOutputSize:outputSize frameHandler:^(CVPixelBufferRef output) {
            Check(NSThread.isMainThread, @"frame delivery is on main queue");
            Check(CVPixelBufferGetWidth(output) == (size_t)outputSize.width && CVPixelBufferGetHeight(output) == (size_t)outputSize.height, @"native output dimensions");
            CVPixelBufferLockBaseAddress(output, kCVPixelBufferLock_ReadOnly);
            const unsigned char *bytes = CVPixelBufferGetBaseAddress(output);
            size_t stride = CVPixelBufferGetBytesPerRow(output);
            const unsigned char *left = bytes + ((size_t)outputSize.height / 2) * stride + ((size_t)outputSize.width / 4) * 4;
            const unsigned char *right = bytes + ((size_t)outputSize.height / 2) * stride + ((size_t)outputSize.width * 3 / 4) * 4;
            Check(left[2] > 180 && left[0] < 60 && left[1] < 60, @"red output remains red");
            Check(right[0] > 180 && right[2] < 60 && right[1] < 60, @"blue output remains blue");
            if (av1FrameIndex >= 0) {
                int patchX = (av1FrameIndex * 72) % ((int)av1InputSize.width - 64);
                size_t x = (size_t)((patchX + 32) * outputSize.width / av1InputSize.width);
                size_t y = (size_t)(40 * outputSize.height / av1InputSize.height);
                const unsigned char *patch = bytes + y * stride + x * 4;
                Check(patch[1] > 180 && patch[0] < 60 && patch[2] < 60, @"AV1 dependent frame updates moving green patch");
            }
            CVPixelBufferUnlockBaseAddress(output, kCVPixelBufferLock_ReadOnly);
            delivered++;
        }];
        Check(decoder != nil, @"create spatial decoder");
        void (^decodeAndCheck)(CMSampleBufferRef) = ^(CMSampleBufferRef sample) {
            __block int expected;
            OnMain(^{
                expected = delivered + 1;
                Check([decoder decodeSampleBuffer:sample], @"submit compressed video");
            });
            NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:10];
            __block BOOL ready = NO;
            do {
                WaitBriefly(0.01);
                OnMain(^{ ready = delivered == expected; });
            } while (!ready && deadline.timeIntervalSinceNow > 0 && !decoder.failed);
            Check(ready && !decoder.failed, @"decode and GPU-scale frame before timeout");
        };
        // Exercise a live decoder format/codec change and repeated frame delivery.
        CMVideoCodecType codecs[] = {kCMVideoCodecType_H264, kCMVideoCodecType_HEVC};
        for (int codec = 0; codec < 2; codec++) for (int pass = 0; pass < 2; pass++) {
            CMSampleBufferRef sample = CreateFrame(pass ? 320 : 640, pass ? 180 : 360, codecs[codec]);
            for (int frame = 0; frame < 8; frame++) decodeAndCheck(sample);
            CFRelease(sample);
        }
        BOOL av1Supported = VTIsHardwareDecodeSupported(kCMVideoCodecType_AV1);
        NSLog(@"AV1 hardware decoding supported: %@", av1Supported ? @"YES" : @"NO");
        NSArray *av1Samples = nil;
        if (av1Supported) {
            for (size_t pass = 0; pass < sizeof(ALAV1Fixtures) / sizeof(ALAV1Fixtures[0]); pass++) {
                const ALAV1Fixture *fixture = &ALAV1Fixtures[pass];
                av1Samples = CreateAV1Samples(fixture);
                NSLog(@"Testing AV1 Main8 SDR: %d × %d → %.0f × %.0f, %zu frames",
                      fixture->width, fixture->height, outputSize.width, outputSize.height, fixture->frameCount);
                for (size_t frame = 0; frame < fixture->frameCount; frame++) {
                    OnMain(^{
                        av1InputSize = CGSizeMake(fixture->width, fixture->height);
                        av1FrameIndex = (int)frame;
                    });
                    decodeAndCheck((__bridge CMSampleBufferRef)av1Samples[frame]);
                }
            }
            OnMain(^{ av1FrameIndex = -1; });
            NSLog(@"PASS: AV1 hardware decode + MetalFX, 32 frames including dependent frames, moving-patch colors and resolution change");
        } else {
            NSLog(@"SKIP: AV1 requires a hardware decoder on this device; H.264/HEVC checks still run.");
        }
        CMSampleBufferRef sample = av1Supported ? NULL : CreateFrame(640, 360, kCMVideoCodecType_H264);
        // Flood the renderer; the two-frame bound must drop excess presentation work.
        __block int beforeStop;
        OnMain(^{
            for (int frame = 0; frame < 40; frame++) {
                CMSampleBufferRef burstFrame = av1Supported ? (__bridge CMSampleBufferRef)av1Samples[frame % av1Samples.count] : sample;
                Check([decoder decodeSampleBuffer:burstFrame], @"bounded burst submission");
            }
            [decoder invalidate];
            beforeStop = delivered;
            Check(![decoder decodeSampleBuffer:av1Supported ? (__bridge CMSampleBufferRef)av1Samples[0] : sample], @"reject frames after stop");
        });
        if (sample) CFRelease(sample);
        WaitBriefly(0.3);
        OnMain(^{ Check(delivered == beforeStop, @"no frame delivered after invalidation"); });
        NSLog(@"PASS: resolution alignment, H.264/HEVC%@ decode, MetalFX dimensions/colors, format changes, %d frames, burst and stop lifecycle",
              av1Supported ? @"/AV1" : @"", av1Supported ? 64 : 32);
    }
    return 0;
}

#if !defined(ASTRALIGHT_EMBED_VIDEO_TESTS)
int main(void) { return ALRunVideoSmokeTests(); }
#endif
#endif
