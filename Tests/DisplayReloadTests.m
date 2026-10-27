// Explicit Debug-only diagnostics. No PC connection, pairing or game launch.
#if DEBUG
#import "StreamFrameViewController.h"
#import "StreamManager.h"
#import "Utils.h"

@interface StreamFrameViewController (DisplayReloadTests)
- (CGSize)currentNativeDisplaySize;
- (StreamManager *)newStreamManager;
- (void)checkForDisplayResolutionChange;
- (void)updateOverlayText:(NSString *)text;
- (void)returnToMainFrame;
@end

static CGSize testNativeSize;
static BOOL useRealScreen;
static NSUInteger starts, stops, completedStops;
static NSTimeInterval shutdownDelay = 0.1;
static NSMutableArray<NSValue *> *requestedSizes;

static void Check(BOOL value, NSString *message) {
    if (!value) { NSLog(@"FAIL display reload: %@", message); abort(); }
}
static void Later(NSTimeInterval seconds, dispatch_block_t block) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC), dispatch_get_main_queue(), block);
}

@interface ALFakeStreamManager : StreamManager
@property (weak) StreamFrameViewController *receiver;
@property BOOL stopped;
@property BOOL stopping;
@property NSMutableArray<dispatch_block_t> *completions;
@end
@implementation ALFakeStreamManager
- (void)main {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.cancelled) return;
        Check(starts == completedStops, @"new connection must wait for old shutdown");
        starts++;
        StreamConfiguration *config = self.receiver.streamConfig;
        [requestedSizes addObject:[NSValue valueWithCGSize:CGSizeMake(config.width, config.height)]];
        NSLog(@"DISPLAY TEST start %lu: input %dx%d native %.0fx%.0f", (unsigned long)starts,
              config.width, config.height, config.nativeSize.width, config.nativeSize.height);
        [self.receiver connectionStarted];
        [self.receiver videoContentShown];
        [self.receiver updateOverlayText:[NSString stringWithFormat:
            @"Display reload diagnostic — no PC connection\nNative %.0f × %.0f · Stream %d × %d\nSession %lu · Fold or unfold the simulator",
            config.nativeSize.width, config.nativeSize.height, config.width, config.height, (unsigned long)starts]];
    });
}
- (NSString *)getStatsOverlayText {
    StreamConfiguration *config = self.receiver.streamConfig;
    return [NSString stringWithFormat:@"Display reload diagnostic — no PC connection\nNative %.0f × %.0f · Stream %d × %d\nSession %lu · Fold or unfold the simulator",
            config.nativeSize.width, config.nativeSize.height, config.width, config.height, (unsigned long)starts];
}
- (void)stopStreamWithCompletion:(dispatch_block_t)completion {
    if (self.stopped) { if (completion) completion(); return; }
    if (!self.completions) self.completions = [NSMutableArray array];
    if (completion) [self.completions addObject:completion];
    if (self.stopping) return;
    self.stopping = YES;
    [self cancel];
    stops++;
    Later(shutdownDelay, ^{
        completedStops++;
        self.stopped = YES;
        NSArray<dispatch_block_t> *pending = [self.completions copy];
        [self.completions removeAllObjects];
        for (dispatch_block_t callback in pending) callback();
    });
}
@end

@interface ALDisplayTestController : StreamFrameViewController
@end
@implementation ALDisplayTestController
- (CGSize)currentNativeDisplaySize {
    return useRealScreen ? [super currentNativeDisplaySize] : testNativeSize;
}
- (StreamManager *)newStreamManager {
    ALFakeStreamManager *manager = [[ALFakeStreamManager alloc] initWithConfig:self.streamConfig renderView:nil connectionCallbacks:self];
    manager.receiver = self;
    return manager;
}
@end

// Exercise real StreamManager cancellation while its launch operation is blocked.
@interface ALPendingLaunchManager : StreamManager
@property dispatch_semaphore_t entered;
@property dispatch_semaphore_t finish;
@end
@implementation ALPendingLaunchManager
- (void)main {
    dispatch_semaphore_signal(self.entered);
    dispatch_semaphore_wait(self.finish, DISPATCH_TIME_FOREVER);
}
@end

static void TestPendingLaunch(dispatch_block_t done) {
    ALPendingLaunchManager *manager = [[ALPendingLaunchManager alloc] initWithConfig:[StreamConfiguration new] renderView:nil connectionCallbacks:nil];
    manager.entered = dispatch_semaphore_create(0);
    manager.finish = dispatch_semaphore_create(0);
    [[NSOperationQueue new] addOperation:manager];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        dispatch_semaphore_wait(manager.entered, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            __block int callbacks = 0;
            [manager stopStreamWithCompletion:^{ callbacks++; }];
            [manager stopStreamWithCompletion:^{ callbacks++; }];
            Later(0.1, ^{
                Check(callbacks == 0, @"stop must wait for pending launch work");
                dispatch_semaphore_signal(manager.finish);
                Later(0.2, ^{
                    Check(callbacks == 2, @"concurrent stop completions each fire once");
                    [manager stopStreamWithCompletion:^{ callbacks++; }];
                    Check(callbacks == 3, @"stop remains idempotent after completion");
                    done();
                });
            });
        });
    });
}

void ALRunDisplayReloadTests(UIWindow *window, BOOL interactive) {
    useRealScreen = interactive;
    testNativeSize = CGSizeMake(2880, 1980);
    requestedSizes = [NSMutableArray array];
    starts = stops = completedStops = 0;
    UIViewController *root = [UIViewController new];
    root.view.backgroundColor = UIColor.blackColor;
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:root];
    window.rootViewController = navigation;
    StreamConfiguration *config = [StreamConfiguration new];
    config.appName = @"Display test";
    config.frameRate = 60;
    config.bitRate = 10000;
    ALDisplayTestController *controller = [ALDisplayTestController new];
    controller.streamConfig = config;
    [navigation pushViewController:controller animated:NO];
    if (interactive) return;

    void (^change)(CGSize) = ^(CGSize size) {
        testNativeSize = size;
        [(ALDisplayTestController *)navigation.topViewController checkForDisplayResolutionChange];
    };
    Later(0.4, ^{
        Check(starts == 1, @"initial stream starts");
        change(testNativeSize);
        Later(0.8, ^{
            Check(starts == 1, @"same-size geometry changes do not reload");
            // Transient/invalid geometry and a fold reversed before debounce.
            change(CGSizeZero);
            change(CGSizeMake(2520, 1080));
            Later(0.15, ^{ change(CGSizeMake(2880, 1980)); });
            Later(1.0, ^{
                Check(starts == 1, @"rapid fold reversal is coalesced");
                change(CGSizeMake(2520, 1080));
                Later(1.0, ^{
                    Check(starts == 2 && stops == 1, @"fold causes exactly one restart");
                    Check(CGSizeEqualToSize(requestedSizes.lastObject.CGSizeValue, CGSizeMake(2520, 1080)), @"fold requests native pixels");
                    Check(UIApplication.sharedApplication.idleTimerDisabled, @"reloaded stream keeps display awake");
                    // Simulate delayed callbacks from the retired connection.
                    [controller connectionStarted];
                    [controller launchFailed:@"stale failure"];
                    Check(controller.presentedViewController == nil, @"stale callbacks are ignored");
                    config.useSpatialUpscaling = YES;
                    change(CGSizeMake(2880, 1980));
                    Later(1.0, ^{
                        Check(starts == 3, @"unfold restarts");
                        Check(CGSizeEqualToSize(requestedSizes.lastObject.CGSizeValue, CGSizeMake(1440, 990)), @"upscaling uses half input and native output");
                        Check(CGSizeEqualToSize(config.nativeSize, CGSizeMake(2880, 1980)), @"upscaler output follows screen");
                        shutdownDelay = 0.5;
                        change(CGSizeMake(2520, 1080));
                        Later(0.8, ^{ change(CGSizeMake(3000, 2000)); });
                        Later(1.5, ^{
                            Check(starts == 4 && stops == 3, @"screen change during shutdown is coalesced");
                            Check(CGSizeEqualToSize(requestedSizes.lastObject.CGSizeValue, CGSizeMake(1500, 1000)), @"restart uses latest screen, not stale target");
                            change(CGSizeMake(2520, 1080));
                            Later(0.8, ^{ [(ALDisplayTestController *)navigation.topViewController returnToMainFrame]; });
                            Later(1.5, ^{
                                Check(starts == 4 && completedStops == 4, [NSString stringWithFormat:@"exit during shutdown prevents reconnect (starts=%lu, stops=%lu, completed=%lu)", (unsigned long)starts, (unsigned long)stops, (unsigned long)completedStops]);
                                Check(navigation.topViewController == root, @"exit returns to root");
                                TestPendingLaunch(^{
                                    NSLog(@"PASS display reload: native/upscaled fold and unfold, same-size/invalid geometry, debounce, latest size during stop, stale callbacks, exit cancellation, pending launch and repeated stop");
                                    UILabel *label = [[UILabel alloc] initWithFrame:root.view.bounds];
                                    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                                    label.text = @"PASS — display reload tests";
                                    label.textColor = UIColor.whiteColor;
                                    label.textAlignment = NSTextAlignmentCenter;
                                    [root.view addSubview:label];
                                });
                            });
                        });
                    });
                });
            });
        });
    });
}
#endif
