// Optional SDR VideoToolbox + MetalFX path. Native streaming uses the existing renderer.
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN
@interface SpatialVideoDecoder : NSObject
@property (atomic, readonly) BOOL failed;
+ (BOOL)isSupported;
// The frame handler runs on the main queue. The pixel buffer is valid for the call.
- (nullable instancetype)initWithOutputSize:(CGSize)size
                              frameHandler:(void (^)(CVPixelBufferRef))handler;
// Call decode and invalidate on the main queue. NO means the caller should fall
// back to its normal decoder and request a fresh IDR frame.
- (BOOL)decodeSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)invalidate;
@end
NS_ASSUME_NONNULL_END
