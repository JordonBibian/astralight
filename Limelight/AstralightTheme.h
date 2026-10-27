// Shared colors and control styling for the iOS browsing interface.
#pragma once
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

static inline UIColor *ALColor(unsigned int rgb) {
    return [UIColor colorWithRed:((rgb >> 16) & 255) / 255.0
                           green:((rgb >> 8) & 255) / 255.0
                            blue:(rgb & 255) / 255.0 alpha:1];
}
static inline UIColor *ALTextColor(void) { return ALColor(0xF4F5FF); }
static inline UIColor *ALSecondaryColor(void) { return ALColor(0xB5C2DF); }
static inline UIColor *ALAccentColor(void) { return ALColor(0xB6C6FF); }

static inline CAGradientLayer *ALBackgroundLayer(UIView *view) {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[(id)ALColor(0x142C55).CGColor, (id)ALColor(0x141D3C).CGColor, (id)ALColor(0x2D1949).CGColor];
    gradient.locations = @[@0, @0.5, @1];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 1);
    gradient.frame = view.bounds;
    [view.layer insertSublayer:gradient atIndex:0];
    view.backgroundColor = ALColor(0x141D3C);
    return gradient;
}
static inline void ALStyleCard(UIView *view) {
    view.backgroundColor = ALColor(0x202D4B);
    view.layer.cornerRadius = 20;
    view.layer.cornerCurve = kCACornerCurveContinuous;
    view.layer.borderWidth = 1;
    view.layer.borderColor = [ALColor(0xA7B9EE) colorWithAlphaComponent:0.24].CGColor;
}
static inline UILabel *ALLabel(CGFloat size, UIFontWeight weight, UIColor *color) {
    UILabel *label = [[UILabel alloc] init];
    label.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:[UIFont systemFontOfSize:size weight:weight] maximumPointSize:size * 1.4];
    label.adjustsFontForContentSizeCategory = YES;
    label.textColor = color;
    return label;
}
static inline UIButtonConfiguration *ALButtonStyle(NSString *title, NSString *symbol) {
    UIButtonConfiguration *config = [UIButtonConfiguration tintedButtonConfiguration];
    if (title) config.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold]}];
    config.preferredSymbolConfigurationForImage = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightMedium];
    config.image = [UIImage systemImageNamed:symbol];
    config.imagePadding = 8;
    config.titleLineBreakMode = NSLineBreakByTruncatingTail;
    config.baseForegroundColor = ALTextColor();
    config.baseBackgroundColor = ALColor(0x8298E9);
    config.cornerStyle = UIButtonConfigurationCornerStyleLarge;
    config.contentInsets = NSDirectionalEdgeInsetsMake(12, 16, 12, 16);
    return config;
}
