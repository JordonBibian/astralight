#pragma once
#include <CoreGraphics/CoreGraphics.h>
#include <math.h>
#include <stdbool.h>

static inline CGSize ALStreamSizeForNativeSize(CGSize nativeSize, bool upscaling) {
    // 4:2:0 encoders require even dimensions. Round only to that boundary.
    double divisor = upscaling ? 4 : 2;
    return CGSizeMake(fmax(2, round(nativeSize.width / divisor) * 2),
                      fmax(2, round(nativeSize.height / divisor) * 2));
}
