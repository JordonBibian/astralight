#import "ALInformationViewController.h"
#import "../AstralightTheme.h"

@implementation ALInformationViewController {
    NSString *_document;
}

- (instancetype)initWithDocument:(NSString *)document title:(NSString *)title {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _document = [document copy];
        self.title = title;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.view.backgroundColor = ALColor(0x101A30);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeDocument)];
    self.navigationItem.rightBarButtonItem.accessibilityIdentifier = @"legalDoneButton";

    UITextView *textView = [[UITextView alloc] init];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.editable = NO;
    textView.selectable = YES;
    textView.dataDetectorTypes = UIDataDetectorTypeLink;
    textView.backgroundColor = UIColor.clearColor;
    textView.textColor = ALTextColor();
    textView.tintColor = ALAccentColor();
    textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    textView.adjustsFontForContentSizeCategory = YES;
    textView.textContainerInset = UIEdgeInsetsMake(20, 20, 32, 20);
    textView.accessibilityIdentifier = @"legalDocumentText";
    NSString *path = [NSBundle.mainBundle pathForResource:_document ofType:@"txt" inDirectory:@"Legal"];
    NSError *error = nil;
    textView.text = path ? [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error] : nil;
    if (textView.text.length == 0) {
        textView.text = @"This document could not be loaded. Visit https://github.com/JordonBibian/astralight for privacy and license information.";
        Log(LOG_E, @"Bundled legal document could not be loaded");
    }
    [self.view addSubview:textView];
    [NSLayoutConstraint activateConstraints:@[
        [textView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [textView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [textView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [textView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
}

- (void)closeDocument {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
