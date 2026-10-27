//
//  LoadingFrameViewController.m
//  Moonlight
//
//  Created by Diego Waxemberg on 2/24/15.
//  Copyright (c) 2015 Moonlight Stream. All rights reserved.
//

#import "LoadingFrameViewController.h"
#import "Utils.h"
#if !TARGET_OS_TV
#import "../AstralightTheme.h"
#endif

@implementation LoadingFrameViewController {
    BOOL presented;
#if !TARGET_OS_TV
    UIView *_connectionCard;
#endif
};

- (void)viewDidLoad {
    [super viewDidLoad];
#if !TARGET_OS_TV
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.view.backgroundColor = [ALColor(0x0B142B) colorWithAlphaComponent:0.78];
    _connectionCard = [[UIView alloc] init];
    ALStyleCard(_connectionCard);
    _connectionCard.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_connectionCard];
    UIActivityIndicatorView *spinner = self.loadingSpinner;
    [_connectionCard addSubview:spinner];
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    spinner.color = ALAccentColor();
    [spinner startAnimating];
    UILabel *label = ALLabel(18, UIFontWeightSemibold, ALTextColor());
    label.text = @"Connecting…";
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [_connectionCard addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [_connectionCard.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_connectionCard.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_connectionCard.widthAnchor constraintEqualToConstant:240],
        [_connectionCard.heightAnchor constraintEqualToConstant:140],
        [spinner.centerXAnchor constraintEqualToAnchor:_connectionCard.centerXAnchor],
        [spinner.topAnchor constraintEqualToAnchor:_connectionCard.topAnchor constant:28],
        [label.centerXAnchor constraintEqualToAnchor:_connectionCard.centerXAnchor],
        [label.bottomAnchor constraintEqualToAnchor:_connectionCard.bottomAnchor constant:-24]
    ]];
#else
    // center the loading spinner
    self.loadingSpinner.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
#endif
}

- (UIViewController*) activeViewController {
    UIViewController *topController = [Utils windowForView:self.viewIfLoaded].rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

- (void)showLoadingFrame:(void (^)(void))completion {
    if (!presented) {
        Log(LOG_I, @"Loading frame presenting start");
        presented = YES;
        [[self activeViewController] presentViewController:self animated:NO completion:^{
            Log(LOG_I, @"Loading frame presenting complete");
            if (completion) {
                completion();
            }
        }];
    }
    else if (completion) {
        Log(LOG_E, @"Loading frame already shown!");
        completion();
    }
}

- (void)dismissLoadingFrame:(void (^)(void))completion {
    if (presented) {
        Log(LOG_I, @"Loading frame hiding start");
        [self dismissViewControllerAnimated:NO completion:^{
            Log(LOG_I, @"Loading frame hiding complete");
            
            // Since presented is set to NO here rather than
            // immediately in dismissLoadingFrame, we may
            // falsely avoid displaying the loading frame if
            // a dismiss is in progress while attempting to show
            // the frame. That's preferable to crashing due to
            // displaying the same VC twice though.
            //
            // This scenario can happen if the app is suspended
            // while the dismiss is in progress then on resume
            // it attempts to display it again before the dismiss
            // completes. It can be reproduced by rapidly pressing
            // Home and switching back to Moonlight while in the app grid.
            // It reproduces more easily if the VC transitions are animated.
            self->presented = NO;
            
            if (completion) {
                completion();
            }
        }];
    }
    else if (completion) {
        completion();
    }
}

- (BOOL)isShown {
    return presented;
}

@end
