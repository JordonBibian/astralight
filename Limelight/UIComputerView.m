//
//  UIComputerView.m
//  Moonlight
//
//  Created by Diego Waxemberg on 10/22/14.
//  Copyright (c) 2014 Moonlight Stream. All rights reserved.
//

#import "UIComputerView.h"
#if !TARGET_OS_TV
#import "AstralightTheme.h"
#endif

@implementation UIComputerView {
    TemporaryHost* _host;
    UIImageView* _hostIcon;
    UILabel* _hostLabel;
    UIImageView* _hostOverlay;
    UIActivityIndicatorView* _hostSpinner;
    id<HostCallback> _callback;
    CGSize _labelSize;
#if !TARGET_OS_TV
    UILabel *_hostStatus;
    UILabel *_hostAction;
    UIView *_statusDot;
#endif
}
static const float REFRESH_CYCLE = 2.0f;

#if TARGET_OS_TV
static const int ITEM_PADDING = 50;
static const int LABEL_DY = 40;
#endif

- (id) init {
    self = [super init];
        
#if TARGET_OS_TV
    self.frame = CGRectMake(0, 0, 400, 400);
#else
    self.frame = CGRectMake(0, 0, 252, 190);
#endif
    
    _hostIcon = [[UIImageView alloc] initWithFrame:self.frame];
    [_hostIcon setImage:[UIImage imageNamed:@"Computer"]];
    
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(5,8);
    self.layer.shadowOpacity = 0.3;

    [self addTarget:self action:@selector(hostButtonSelected:) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(hostButtonDeselected:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
    
    _hostLabel = [[UILabel alloc] init];
    _hostLabel.textColor = [UIColor whiteColor];
    
    _hostOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width / 3, _hostIcon.frame.size.height / 4, _hostIcon.frame.size.width / 3, self.frame.size.height / 3)];
    _hostSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _hostSpinner.color = UIColor.whiteColor;
    [_hostSpinner setFrame:_hostOverlay.frame];
    _hostSpinner.userInteractionEnabled = NO;
    _hostSpinner.hidesWhenStopped = YES;

    [self addSubview:_hostLabel];
    [self addSubview:_hostIcon];
    
#if TARGET_OS_TV
    _hostIcon.clipsToBounds = NO;
    _hostIcon.adjustsImageWhenAncestorFocused = YES;
    _hostIcon.masksFocusEffectToContents = YES;
    
    
    _hostOverlay.masksFocusEffectToContents = YES;
    _hostOverlay.adjustsImageWhenAncestorFocused = NO;
    
    [_hostIcon.overlayContentView addSubview:_hostOverlay];
    [_hostIcon.overlayContentView addSubview:_hostSpinner];
#else
    [self addSubview:_hostOverlay];
    [self addSubview:_hostSpinner];
    ALStyleCard(self);
    self.layer.shadowOpacity = 0;
    _hostIcon.image = [UIImage systemImageNamed:@"desktopcomputer"];
    _hostIcon.tintColor = ALAccentColor();
    _hostIcon.contentMode = UIViewContentModeScaleAspectFit;
    _hostLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    _hostLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _hostStatus = ALLabel(14, UIFontWeightRegular, ALSecondaryColor());
    _hostAction = ALLabel(14, UIFontWeightSemibold, ALAccentColor());
    _statusDot = [[UIView alloc] init];
    _statusDot.layer.cornerRadius = 4;
    [self addSubview:_hostStatus];
    [self addSubview:_hostAction];
    [self addSubview:_statusDot];
    self.isAccessibilityElement = YES;
    self.accessibilityTraits = UIAccessibilityTraitButton;

    if (@available(iOS 13.4.1, *)) {
        // Allow the button style to change when moused over
        self.pointerInteractionEnabled = YES;
    }
#endif
    
    return self;
}

- (void) hostButtonSelected:(id)sender {
    _hostIcon.layer.opacity = 0.5f;
    _hostSpinner.layer.opacity = 0.5f;
    _hostOverlay.layer.opacity = 0.5f;
}
- (void) hostButtonDeselected:(id)sender {
    _hostIcon.layer.opacity = 1.0f;
    _hostSpinner.layer.opacity = 1.0f;
    _hostOverlay.layer.opacity = 1.0f;
}

- (id) initForAddWithCallback:(id<HostCallback>)callback {
    self = [self init];
    _callback = callback;
    
    [self addTarget:self action:@selector(addClicked) forControlEvents:UIControlEventPrimaryActionTriggered];
    
    [_hostLabel setText:@"Add Host Manually"];
    [_hostLabel sizeToFit];
    
    [_hostOverlay setImage:[UIImage imageNamed:@"AddOverlayIcon"]];
#if !TARGET_OS_TV
    _hostLabel.text = @"Add a computer";
    _hostIcon.image = [UIImage systemImageNamed:@"plus.circle"];
    _hostOverlay.image = nil;
    _hostStatus.text = @"Connect using an IP address";
    _hostAction.text = @"Add manually  →";
    _statusDot.hidden = YES;
    self.accessibilityLabel = @"Add a computer manually";
    self.accessibilityIdentifier = @"addComputerButton";
#endif
    
    [self updateBounds];
        
    return self;
}

- (id) initWithComputer:(TemporaryHost*)host andCallback:(id<HostCallback>)callback {
    self = [self init];
    _host = host;
    _callback = callback;
    
    // Use UIContextMenuInteraction on iOS 13.0+ and a standard UILongPressGestureRecognizer
    // for tvOS devices and iOS prior to 13.0.
#if !TARGET_OS_TV
    if (@available(iOS 13.0, *)) {
        UIContextMenuInteraction* rightClickInteraction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
        [self addInteraction:rightClickInteraction];
    }
    else
#endif
    {
        UILongPressGestureRecognizer* longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(hostLongClicked:)];
        [self addGestureRecognizer:longPressRecognizer];
    }
    
    [self addTarget:self action:@selector(hostClicked) forControlEvents:UIControlEventPrimaryActionTriggered];
    
    [self updateContentsForHost:host];

    return self;
}

- (void)didMoveToSuperview {
    // Start our update loop when we are added to our cell
    if (self.superview != nil && _host != nil) {
        [self updateLoop];
    }
}

#if !TARGET_OS_TV
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    _hostIcon.frame = CGRectMake(20, 20, 48, 40);
    _hostOverlay.frame = CGRectMake(width - 48, 24, 24, 24);
    _hostSpinner.center = CGPointMake(width - 34, 36);
    _statusDot.frame = CGRectMake(width - 34, 32, 8, 8);
    _hostLabel.frame = CGRectMake(20, 80, width - 40, 26);
    _hostStatus.frame = CGRectMake(20, 111, width - 40, 22);
    _hostAction.frame = CGRectMake(20, 151, width - 40, 22);
}
#endif

- (void) updateBounds {
#if !TARGET_OS_TV
    [self setNeedsLayout];
#else
    float x = FLT_MAX;
    float y = FLT_MAX;
    float width = 0;
    float height;
    
    float iconX = _hostIcon.frame.origin.x + _hostIcon.frame.size.width / 2;
    _hostLabel.center = CGPointMake(iconX, _hostIcon.frame.origin.y + _hostIcon.frame.size.height + LABEL_DY);
    
    x = MIN(x, _hostIcon.frame.origin.x);
    x = MIN(x, _hostLabel.frame.origin.x);
    
    y = MIN(y, _hostIcon.frame.origin.y);
    y = MIN(y, _hostLabel.frame.origin.y);

    width = MAX(width, _hostIcon.frame.size.width);
    width = MAX(width, _hostLabel.frame.size.width);
    
    height = _hostIcon.frame.size.height +
        _hostLabel.frame.size.height +
        LABEL_DY / 2;
    
    self.bounds = CGRectMake(x - ITEM_PADDING, y - ITEM_PADDING, width + 2 * ITEM_PADDING, height + 2 * ITEM_PADDING);
#endif
}

- (void) updateContentsForHost:(TemporaryHost*)host {
    _hostLabel.text = _host.name;
    [_hostLabel sizeToFit];
    
    if (host.state == StateOnline) {
        [_hostSpinner stopAnimating];

        if (host.pairState == PairStateUnpaired) {
            [_hostOverlay setImage:[UIImage imageNamed:@"LockedOverlayIcon"]];
        }
        else {
            [_hostOverlay setImage:nil];
        }
    }
    else if (host.state == StateOffline) {
        [_hostSpinner stopAnimating];
        [_hostOverlay setImage:[UIImage imageNamed:@"ErrorOverlayIcon"]];
    }
    else {
        [_hostSpinner startAnimating];
    }
    
#if !TARGET_OS_TV
    _hostOverlay.image = nil;
    _statusDot.hidden = host.state == StateUnknown;
    if (host.state == StateOnline) {
        _statusDot.backgroundColor = ALColor(0x77E2BC);
        _hostStatus.text = host.pairState == PairStatePaired ? @"Online · Paired" : @"Online · Ready to pair";
        _hostAction.text = host.pairState == PairStatePaired ? @"Open library  →" : @"Pair computer  →";
    } else if (host.state == StateOffline) {
        _statusDot.backgroundColor = ALColor(0xF3BE7C);
        _hostStatus.text = @"Offline";
        _hostAction.text = @"Wake or manage  →";
    } else {
        _hostStatus.text = @"Checking connection…";
        _hostAction.text = @"Please wait";
    }
    self.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", _hostLabel.text, _hostStatus.text];
    self.accessibilityHint = @"Touch and hold for computer options.";
#endif
    [self updateBounds];
}

- (void) updateLoop {
    // Stop immediately if the view has been detached
    if (self.superview == nil) {
        return;
    }
    
    [self updateContentsForHost:_host];
    
    // Queue the next refresh cycle
    [self performSelector:@selector(updateLoop) withObject:self afterDelay:REFRESH_CYCLE];
}

- (void) hostLongClicked:(UILongPressGestureRecognizer*)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [_callback hostLongClicked:_host view:self];
    }
}

#if !TARGET_OS_TV
- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction
                        configurationForMenuAtLocation:(CGPoint)location {
    // We don't want to trigger the primary action at this point, so cancel
    // tracking touch on this view now. This will also have the (intended)
    // effect of removing the touch highlight on this view.
    [self cancelTrackingWithEvent:nil];
    
    [_callback hostLongClicked:_host view:self];
    return nil;
}
#endif

- (void) hostClicked {
    [_callback hostClicked:_host view:self];
}

- (void) addClicked {
    [_callback addHostClicked];
}

@end
