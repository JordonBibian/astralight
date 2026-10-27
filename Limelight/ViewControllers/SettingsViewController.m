//
//  SettingsViewController.m
//  Moonlight
//
//  Created by Diego Waxemberg on 10/27/14.
//  Copyright (c) 2014 Moonlight Stream. All rights reserved.
//

#import "SettingsViewController.h"
#import "TemporarySettings.h"
#import "DataManager.h"
#import "Utils.h"
#import "SpatialVideoDecoder.h"
#import "SWRevealViewController.h"
#import "ALInformationViewController.h"
#import "../AstralightTheme.h"

#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>

@implementation SettingsViewController {
    NSInteger _bitrate;
    BOOL _hdrSupported;
    CAGradientLayer *_settingsGradient;
    UIStackView *_settingsStack;
    NSLayoutConstraint *_settingsLeading;
    NSLayoutConstraint *_settingsTrailing;

}

@dynamic overrideUserInterfaceStyle;

static NSString* bitrateFormat = @"Bitrate: %.1f Mbps";
static const int bitrateTable[] = {
    500,
    1000,
    1500,
    2000,
    2500,
    3000,
    4000,
    5000,
    6000,
    7000,
    8000,
    9000,
    10000,
    12000,
    15000,
    18000,
    20000,
    30000,
    40000,
    50000,
    60000,
    70000,
    80000,
    100000,
    120000,
    150000,
};


-(int)getSliderValueForBitrate:(NSInteger)bitrate {
    int i;
    
    for (i = 0; i < (sizeof(bitrateTable) / sizeof(*bitrateTable)); i++) {
        if (bitrate <= bitrateTable[i]) {
            return i;
        }
    }
    
    // Return the last entry in the table
    return i - 1;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateResolutionDisplayViewText];
    _settingsLeading.constant = MAX(24, self.view.safeAreaInsets.left + 16);
    // The reveal container includes an overdraw region covered by the library.
    _settingsTrailing.constant = -(24 + self.revealViewController.rearViewRevealOverdraw);
    [self updateSettingsGradient];
}

- (void)updateSettingsGradient {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _settingsGradient.frame = self.scrollView.bounds;
    [CATransaction commit];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateSettingsGradient];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    [self.view setNeedsLayout];
}

- (void)closeSettings {
    [self saveSettings];
    [self.revealViewController revealToggleAnimated:YES];
}

- (UIView *)settingWithTitle:(NSString *)title control:(UIView *)control {
    UILabel *label = ALLabel(15, UIFontWeightSemibold, ALTextColor());
    label.text = title;
    label.numberOfLines = 0;
    control.translatesAutoresizingMaskIntoConstraints = NO;
    control.accessibilityLabel = title;
    [control.heightAnchor constraintGreaterThanOrEqualToConstant:44].active = YES;
    if ([control isKindOfClass:UISegmentedControl.class]) {
        UISegmentedControl *segments = (UISegmentedControl *)control;
        segments.backgroundColor = ALColor(0x131F3B);
        segments.selectedSegmentTintColor = ALColor(0x536AC1);
        [segments setTitleTextAttributes:@{NSForegroundColorAttributeName: ALSecondaryColor(), NSFontAttributeName:[UIFont systemFontOfSize:13 weight:UIFontWeightMedium]} forState:UIControlStateNormal];
        [segments setTitleTextAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor} forState:UIControlStateSelected];
        [segments setTitleTextAttributes:@{NSForegroundColorAttributeName: ALColor(0x7885A0)} forState:UIControlStateDisabled];
    }
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[label, control]];
    row.axis = UILayoutConstraintAxisVertical;
    row.spacing = 10;
    return row;
}

- (void)addSettingsSection:(NSString *)title rows:(NSArray<UIView *> *)rows {
    UILabel *heading = ALLabel(18, UIFontWeightBold, ALTextColor());
    heading.text = title;
    heading.accessibilityTraits = UIAccessibilityTraitHeader;
    NSMutableArray<UIView *> *contents = [NSMutableArray arrayWithObject:heading];
    [contents addObjectsFromArray:rows];
    UIStackView *card = [[UIStackView alloc] initWithArrangedSubviews:contents];
    card.axis = UILayoutConstraintAxisVertical;
    card.spacing = 22;
    card.layoutMargins = UIEdgeInsetsMake(20, 20, 20, 20);
    card.layoutMarginsRelativeArrangement = YES;
    ALStyleCard(card);
    [_settingsStack addArrangedSubview:card];
}

- (UIButton *)informationButton:(NSString *)title symbol:(NSString *)symbol action:(SEL)action identifier:(NSString *)identifier {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.configuration = ALButtonStyle(title, symbol);
    button.accessibilityIdentifier = identifier;
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:48].active = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)showDocument:(NSString *)document title:(NSString *)title {
    ALInformationViewController *controller = [[ALInformationViewController alloc] initWithDocument:document title:title];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:controller];
    navigation.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    navigation.navigationBar.tintColor = ALAccentColor();
    navigation.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:navigation animated:YES completion:nil];
}

- (void)showPrivacyPolicy {
    [self showDocument:@"Privacy" title:@"Privacy Policy"];
}

- (void)showLicenses {
    [self showDocument:@"Licenses" title:@"Credits & Licenses"];
}

- (void)showSourceCode {
    [Utils launchUrl:@"https://github.com/JordonBibian/astralight"];
}

- (void)configureSettingsAppearance {
    // Retain and reuse the storyboard controls, including their existing actions.
    for (UIView *view in self.scrollView.subviews.copy) [view removeFromSuperview];
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    self.scrollView.delegate = self;
    self.scrollView.tintColor = ALAccentColor();
    _settingsGradient = ALBackgroundLayer(self.scrollView);
    _settingsStack = [[UIStackView alloc] init];
    _settingsStack.axis = UILayoutConstraintAxisVertical;
    _settingsStack.spacing = 20;
    _settingsStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:_settingsStack];
    _settingsLeading = [_settingsStack.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor constant:24];
    _settingsTrailing = [_settingsStack.trailingAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.trailingAnchor constant:-24];
    [NSLayoutConstraint activateConstraints:@[
        _settingsLeading, _settingsTrailing,
        [_settingsStack.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor constant:28],
        [_settingsStack.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor constant:-40],
        [self.scrollView.contentLayoutGuide.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor]
    ]];
    UILabel *title = ALLabel(30, UIFontWeightBold, ALTextColor());
    title.text = @"Settings";
    title.accessibilityTraits = UIAccessibilityTraitHeader;
    UIButton *done = [UIButton buttonWithType:UIButtonTypeSystem];
    done.configuration = ALButtonStyle(@"Done", @"checkmark");
    done.accessibilityIdentifier = @"settingsDoneButton";
    [done addTarget:self action:@selector(closeSettings) forControlEvents:UIControlEventTouchUpInside];
    [done setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    UIStackView *header = [[UIStackView alloc] initWithArrangedSubviews:@[title, done]];
    header.alignment = UIStackViewAlignmentCenter;
    header.spacing = 16;
    [_settingsStack addArrangedSubview:header];
    UILabel *subtitle = ALLabel(14, UIFontWeightRegular, ALSecondaryColor());
    subtitle.text = @"Make the stream yours. Changes apply to your next session.";
    subtitle.numberOfLines = 0;
    [_settingsStack addArrangedSubview:subtitle];

    self.resolutionDisplayView.backgroundColor = ALColor(0x16233F);
    self.resolutionDisplayView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.resolutionDisplayView.heightAnchor constraintEqualToConstant:58].active = YES;
    self.bitrateLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.bitrateLabel.textColor = ALTextColor();
    self.bitrateSlider.minimumTrackTintColor = ALColor(0x8AA6FF);
    self.bitrateSlider.maximumTrackTintColor = ALColor(0x3B486B);
    self.bitrateSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bitrateSlider.heightAnchor constraintEqualToConstant:44].active = YES;
    UIStackView *bitrate = [[UIStackView alloc] initWithArrangedSubviews:@[self.bitrateLabel, self.bitrateSlider]];
    bitrate.axis = UILayoutConstraintAxisVertical;
    bitrate.spacing = 8;

    [self addSettingsSection:@"Video" rows:@[
        [self settingWithTitle:@"Resolution" control:self.resolutionSelector], self.resolutionDisplayView,
        [self settingWithTitle:@"Frame rate" control:self.framerateSelector], bitrate]];
    [self addSettingsSection:@"Picture & performance" rows:@[
        [self settingWithTitle:@"Preferred codec" control:self.codecSelector],
        [self settingWithTitle:@"HDR" control:self.hdrSelector],
        [self settingWithTitle:@"Frame pacing" control:self.framePacingSelector],
        [self settingWithTitle:@"Optimize game settings" control:self.optimizeSettingsSelector]]];
    [self addSettingsSection:@"Controls" rows:@[
        [self settingWithTitle:@"Touch mode" control:self.touchModeSelector],
        [self settingWithTitle:@"On-screen controls" control:self.onscreenControlSelector],
        [self settingWithTitle:@"Multiple controllers" control:self.multiControllerSelector],
        [self settingWithTitle:@"Swap A/B and X/Y" control:self.swapABXYButtonsSelector],
        [self settingWithTitle:@"Citrix X1 mouse" control:self.btMouseSelector]]];
    [self addSettingsSection:@"Audio & diagnostics" rows:@[
        [self settingWithTitle:@"Play audio on PC" control:self.audioOnPCSelector],
        [self settingWithTitle:@"Statistics overlay" control:self.statsOverlaySelector]]];
    UILabel *version = ALLabel(14, UIFontWeightRegular, ALSecondaryColor());
    version.numberOfLines = 0;
    version.text = [NSString stringWithFormat:@"Version %@ (%@) · Independent Moonlight fork",
        [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
        [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"]];
    [self addSettingsSection:@"About Astralight" rows:@[
        version,
        [self informationButton:@"Privacy Policy" symbol:@"hand.raised" action:@selector(showPrivacyPolicy) identifier:@"privacyPolicyButton"],
        [self informationButton:@"Credits & Licenses" symbol:@"doc.text" action:@selector(showLicenses) identifier:@"licensesButton"],
        [self informationButton:@"Source Code" symbol:@"chevron.left.forwardslash.chevron.right" action:@selector(showSourceCode) identifier:@"sourceCodeButton"]]];
    UIButton *doneFooter = [UIButton buttonWithType:UIButtonTypeSystem];
    doneFooter.configuration = ALButtonStyle(@"Done", @"checkmark");
    doneFooter.accessibilityIdentifier = @"settingsDoneFooterButton";
    [doneFooter.heightAnchor constraintGreaterThanOrEqualToConstant:48].active = YES;
    [doneFooter addTarget:self action:@selector(closeSettings) forControlEvents:UIControlEventTouchUpInside];
    [_settingsStack addArrangedSubview:doneFooter];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Always run settings in dark mode because we want the light fonts
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
    
    DataManager* dataMan = [[DataManager alloc] init];
    TemporarySettings* currentSettings = [dataMan getSettings];
    
    // Ensure we pick a bitrate that falls exactly onto a slider notch
    _bitrate = bitrateTable[[self getSliderValueForBitrate:[currentSettings.bitrate intValue]]];

    self.resolutionDisplayView.layer.cornerRadius = 10;
    self.resolutionDisplayView.clipsToBounds = YES;
    [self.resolutionSelector removeAllSegments];
    [self.resolutionSelector insertSegmentWithTitle:@"Native" atIndex:0 animated:NO];
    [self.resolutionSelector insertSegmentWithTitle:@"Upscaled (SDR)" atIndex:1 animated:NO];
    BOOL upscalingSupported = [SpatialVideoDecoder isSupported];
    [self.resolutionSelector setEnabled:upscalingSupported forSegmentAtIndex:1];
    NSInteger resolution = upscalingSupported && [NSUserDefaults.standardUserDefaults boolForKey:AstralightSpatialUpscalingEnabled] ? 1 : 0;

    NSInteger framerate;
    switch ([currentSettings.framerate integerValue]) {
        case 30:
            framerate = 0;
            break;
        default:
        case 60:
            framerate = 1;
            break;
        case 120:
            framerate = 2;
            break;
    }

    // Only show the 120 FPS option if we have a > 60-ish Hz display
    bool enable120Fps = false;
    if (@available(iOS 10.3, tvOS 10.3, *)) {
        if ([Utils screenForView:self.view].maximumFramesPerSecond > 62) {
            enable120Fps = true;
        }
    }
    if (!enable120Fps) {
        [self.framerateSelector removeSegmentAtIndex:2 animated:NO];
    }

    // Disable codec selector segments for unsupported codecs
#if defined(__IPHONE_16_0) || defined(__TVOS_16_0)
    if (!VTIsHardwareDecodeSupported(kCMVideoCodecType_AV1))
#endif
    {
        [self.codecSelector removeSegmentAtIndex:2 animated:NO];
    }
    if (!VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC)) {
        [self.codecSelector removeSegmentAtIndex:1 animated:NO];

    }
    switch (currentSettings.preferredCodec) {
        case CODEC_PREF_AUTO:
            [self.codecSelector setSelectedSegmentIndex:self.codecSelector.numberOfSegments - 1];
            break;
            
        case CODEC_PREF_AV1:
            [self.codecSelector setSelectedSegmentIndex:2];
            break;
            
        case CODEC_PREF_HEVC:
            [self.codecSelector setSelectedSegmentIndex:1];
            break;
            
        case CODEC_PREF_H264:
            [self.codecSelector setSelectedSegmentIndex:0];
            break;
    }
    
    if (!VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC) || !AVPlayer.eligibleForHDRPlayback) {
        [self.hdrSelector removeAllSegments];
        [self.hdrSelector insertSegmentWithTitle:@"Unsupported on this device" atIndex:0 animated:NO];
        [self.hdrSelector setEnabled:NO];
    }
    else {
        [self.hdrSelector setSelectedSegmentIndex:currentSettings.enableHdr ? 1 : 0];
    }
    
    [self.touchModeSelector setSelectedSegmentIndex:currentSettings.absoluteTouchMode ? 1 : 0];
    [self.touchModeSelector addTarget:self action:@selector(touchModeChanged) forControlEvents:UIControlEventValueChanged];
    [self.statsOverlaySelector setSelectedSegmentIndex:currentSettings.statsOverlay ? 1 : 0];
    [self.btMouseSelector setSelectedSegmentIndex:currentSettings.btMouseSupport ? 1 : 0];
    [self.optimizeSettingsSelector setSelectedSegmentIndex:currentSettings.optimizeGames ? 1 : 0];
    [self.framePacingSelector setSelectedSegmentIndex:currentSettings.useFramePacing ? 1 : 0];
    [self.multiControllerSelector setSelectedSegmentIndex:currentSettings.multiController ? 1 : 0];
    [self.swapABXYButtonsSelector setSelectedSegmentIndex:currentSettings.swapABXYButtons ? 1 : 0];
    [self.audioOnPCSelector setSelectedSegmentIndex:currentSettings.playAudioOnPC ? 1 : 0];
    NSInteger onscreenControls = [currentSettings.onscreenControls integerValue];
    _hdrSupported = self.hdrSelector.enabled;
    self.hdrSelector.enabled = _hdrSupported && resolution == 0;
    [self.resolutionSelector setSelectedSegmentIndex:resolution];
    [self.resolutionSelector addTarget:self action:@selector(newResolutionChosen) forControlEvents:UIControlEventValueChanged];
    [self.framerateSelector setSelectedSegmentIndex:framerate];
    [self.framerateSelector addTarget:self action:@selector(updateBitrate) forControlEvents:UIControlEventValueChanged];
    [self.onscreenControlSelector setSelectedSegmentIndex:onscreenControls];
    [self.onscreenControlSelector setEnabled:!currentSettings.absoluteTouchMode];
    [self.bitrateSlider setMinimumValue:0];
    [self.bitrateSlider setMaximumValue:(sizeof(bitrateTable) / sizeof(*bitrateTable)) - 1];
    [self.bitrateSlider setValue:[self getSliderValueForBitrate:_bitrate] animated:YES];
    [self.bitrateSlider addTarget:self action:@selector(bitrateSliderMoved) forControlEvents:UIControlEventValueChanged];
    [self configureSettingsAppearance];
    [self updateBitrateText];
    [self updateResolutionDisplayViewText];
}

- (void) touchModeChanged {
    // Disable on-screen controls in absolute touch mode
    [self.onscreenControlSelector setEnabled:[self.touchModeSelector selectedSegmentIndex] == 0];
}

- (void) updateBitrate {
    NSInteger fps = [self getChosenFrameRate];
    NSInteger width = [self getChosenStreamWidth];
    NSInteger height = [self getChosenStreamHeight];
    NSInteger defaultBitrate;
    
    // This logic is shamelessly stolen from Moonlight Qt:
    // https://github.com/moonlight-stream/moonlight-qt/blob/master/app/settings/streamingpreferences.cpp
    
    // Don't scale bitrate linearly beyond 60 FPS. It's definitely not a linear
    // bitrate increase for frame rate once we get to values that high.
    float frameRateFactor = (fps <= 60 ? fps : (sqrtf(fps / 60.f) * 60.f)) / 30.f;

    // TODO: Collect some empirical data to see if these defaults make sense.
    // We're just using the values that the Shield used, as we have for years.
    struct {
        NSInteger pixels;
        int factor;
    } resTable[] = {
        { 640 * 360, 1 },
        { 854 * 480, 2 },
        { 1280 * 720, 5 },
        { 1920 * 1080, 10 },
        { 2560 * 1440, 20 },
        { 3840 * 2160, 40 },
        { -1, -1 }
    };

    // Calculate the resolution factor by linear interpolation of the resolution table
    float resolutionFactor;
    NSInteger pixels = width * height;
    for (int i = 0;; i++) {
        if (pixels == resTable[i].pixels) {
            // We can bail immediately for exact matches
            resolutionFactor = resTable[i].factor;
            break;
        }
        else if (pixels < resTable[i].pixels) {
            if (i == 0) {
                // Never go below the lowest resolution entry
                resolutionFactor = resTable[i].factor;
            }
            else {
                // Interpolate between the entry greater than the chosen resolution (i) and the entry less than the chosen resolution (i-1)
                resolutionFactor = ((float)(pixels - resTable[i-1].pixels) / (resTable[i].pixels - resTable[i-1].pixels)) * (resTable[i].factor - resTable[i-1].factor) + resTable[i-1].factor;
            }
            break;
        }
        else if (resTable[i].pixels == -1) {
            // Never go above the highest resolution entry
            resolutionFactor = resTable[i-1].factor;
            break;
        }
    }

    defaultBitrate = round(resolutionFactor * frameRateFactor) * 1000;
    _bitrate = MIN(defaultBitrate, 100000);
    [self.bitrateSlider setValue:[self getSliderValueForBitrate:_bitrate] animated:YES];
    
    [self updateBitrateText];
}

- (void) newResolutionChosen {
    self.hdrSelector.enabled = _hdrSupported && self.resolutionSelector.selectedSegmentIndex == 0;
    [self updateBitrate];
    [self updateResolutionDisplayViewText];
}

- (void) updateResolutionDisplayViewText {
    CGSize nativeSize = [Utils nativeDisplaySizeForView:self.view];
    BOOL upscaling = self.resolutionSelector.selectedSegmentIndex == 1;
    CGSize inputSize = [Utils streamSizeForNativeSize:nativeSize upscaling:upscaling];
    for (UIView *subview in self.resolutionDisplayView.subviews) [subview removeFromSuperview];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(self.resolutionDisplayView.bounds, 8, 0)];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.numberOfLines = 2;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:12];
    label.textColor = ALSecondaryColor();
    label.adjustsFontSizeToFitWidth = YES;
    label.text = upscaling ?
        [NSString stringWithFormat:@"%.0f × %.0f → %.0f × %.0f\nMetalFX upscaling • SDR", inputSize.width, inputSize.height, nativeSize.width, nativeSize.height] :
        [NSString stringWithFormat:@"Native display: %.0f × %.0f\nFull-resolution streaming", nativeSize.width, nativeSize.height];
    [self.resolutionDisplayView addSubview:label];
}

- (void) bitrateSliderMoved {
    assert(self.bitrateSlider.value < (sizeof(bitrateTable) / sizeof(*bitrateTable)));
    _bitrate = bitrateTable[(int)self.bitrateSlider.value];
    [self updateBitrateText];
}

- (void) updateBitrateText {
    // Display bitrate in Mbps
    [self.bitrateLabel setText:[NSString stringWithFormat:bitrateFormat, _bitrate / 1000.]];
}

- (NSInteger) getChosenFrameRate {
    switch ([self.framerateSelector selectedSegmentIndex]) {
        case 0:
            return 30;
        case 1:
            return 60;
        case 2:
            return 120;
        default:
            abort();
    }
}

- (uint32_t) getChosenCodecPreference {
    // Auto is always the last segment
    if (self.codecSelector.selectedSegmentIndex == self.codecSelector.numberOfSegments - 1) {
        return CODEC_PREF_AUTO;
    }
    else {
        switch (self.codecSelector.selectedSegmentIndex) {
            case 0:
                return CODEC_PREF_H264;
                
            case 1:
                return CODEC_PREF_HEVC;
                
            case 2:
                return CODEC_PREF_AV1;
                
            default:
                abort();
        }
    }
}

- (NSInteger) getChosenStreamHeight {
    return [Utils streamSizeForNativeSize:[Utils nativeDisplaySizeForView:self.view]
                               upscaling:self.resolutionSelector.selectedSegmentIndex == 1].height;
}

- (NSInteger) getChosenStreamWidth {
    return [Utils streamSizeForNativeSize:[Utils nativeDisplaySizeForView:self.view]
                               upscaling:self.resolutionSelector.selectedSegmentIndex == 1].width;
}

- (void) saveSettings {
    [NSUserDefaults.standardUserDefaults setBool:self.resolutionSelector.selectedSegmentIndex == 1 forKey:AstralightSpatialUpscalingEnabled];
    DataManager* dataMan = [[DataManager alloc] init];
    NSInteger framerate = [self getChosenFrameRate];
    NSInteger height = [self getChosenStreamHeight];
    NSInteger width = [self getChosenStreamWidth];
    NSInteger onscreenControls = [self.onscreenControlSelector selectedSegmentIndex];
    BOOL optimizeGames = [self.optimizeSettingsSelector selectedSegmentIndex] == 1;
    BOOL multiController = [self.multiControllerSelector selectedSegmentIndex] == 1;
    BOOL swapABXYButtons = [self.swapABXYButtonsSelector selectedSegmentIndex] == 1;
    BOOL audioOnPC = [self.audioOnPCSelector selectedSegmentIndex] == 1;
    uint32_t preferredCodec = [self getChosenCodecPreference];
    BOOL btMouseSupport = [self.btMouseSelector selectedSegmentIndex] == 1;
    BOOL useFramePacing = [self.framePacingSelector selectedSegmentIndex] == 1;
    BOOL absoluteTouchMode = [self.touchModeSelector selectedSegmentIndex] == 1;
    BOOL statsOverlay = [self.statsOverlaySelector selectedSegmentIndex] == 1;
    BOOL enableHdr = [self.hdrSelector selectedSegmentIndex] == 1;
    [dataMan saveSettingsWithBitrate:_bitrate
                           framerate:framerate
                              height:height
                               width:width
                         audioConfig:2 // Stereo
                    onscreenControls:onscreenControls
                       optimizeGames:optimizeGames
                     multiController:multiController
                     swapABXYButtons:swapABXYButtons
                           audioOnPC:audioOnPC
                      preferredCodec:preferredCodec
                      useFramePacing:useFramePacing
                           enableHdr:enableHdr
                      btMouseSupport:btMouseSupport
                   absoluteTouchMode:absoluteTouchMode
                        statsOverlay:statsOverlay];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}


@end
