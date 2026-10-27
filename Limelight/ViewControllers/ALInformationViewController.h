#import <UIKit/UIKit.h>

// Offline release documents remain available without a network connection.
@interface ALInformationViewController : UIViewController
- (instancetype)initWithDocument:(NSString *)document title:(NSString *)title;
@end
