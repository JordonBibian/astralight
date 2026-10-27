#import "SceneDelegate.h"
#import "AppDelegate.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }

    // Preserve cold-launch PC shortcuts before the main view appears.
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    appDelegate.pcUuidToLoad = (NSString *)connectionOptions.shortcutItem.userInfo[@"UUID"];

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];

    NSString *storyboardName = windowScene.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
    self.window.rootViewController = [storyboard instantiateInitialViewController];
    [self.window makeKeyAndVisible];
}

- (void)windowScene:(UIWindowScene *)windowScene performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    appDelegate.pcUuidToLoad = (NSString *)shortcutItem.userInfo[@"UUID"];
    appDelegate.shortcutCompletionHandler = completionHandler;
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    [(AppDelegate *)UIApplication.sharedApplication.delegate saveContext];
}

@end
