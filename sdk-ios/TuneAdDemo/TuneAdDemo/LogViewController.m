//
//  LogViewController.m
//  TuneAdDemo
//
//  Created by Harshal Ogale on 2/16/15.
//  Copyright (c) 2015 HasOffers Inc. All rights reserved.
//

#import "LogViewController.h"

@import MessageUI;

@interface LogViewController () <UITextViewDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;

- (IBAction)clearLog:(id)sender;

@end

BOOL toggleFlag = NO;
UIFont *font;
BOOL shouldAutoScroll = YES;
NSMutableAttributedString *debugLog;

@implementation LogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _textView.contentInset = UIEdgeInsetsMake(5, 5, 5, 5);
    
    debugLog = [NSMutableAttributedString new];
    
    UIFont *basicFont = [UIFont fontWithName:@"Courier" size:18];
    UIFontDescriptor *basicFontDescriptor = [basicFont fontDescriptor];
    UIFontDescriptor *boldFontDescriptor = [basicFontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    UIFont *boldFont = [UIFont fontWithDescriptor:boldFontDescriptor size:18];
    
    font = boldFont;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleText:)
                                                 name:@"TuneAdDemoNewLogText"
                                               object:nil];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateTextbox];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handleText:(NSNotification *)notification
{
    [self appendText:notification.userInfo[@"object"]];
    [self updateTextbox];
}

- (IBAction)clearLog:(id)sender {
    debugLog = [NSMutableAttributedString new];
    
    [self updateTextbox];
}

- (IBAction)showEmail:(id)sender {
    // Email Subject
    NSString *emailTitle = @"iOS Alliances Demo App debug log";
    // Email Content
    NSString *messageBody = [NSString stringWithFormat:@"debug log:\n\n%@", _textView.text];
    // To address
    NSArray *toRecipents = @[@"sam@tune.com", @"alfred@tune.com", @"rex@tune.com", @"john@tune.com", @"harshal@tune.com"];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc setToRecipients:toRecipents];
    
    // Present mail view controller on screen
    [self presentViewController:mc animated:YES completion:NULL];
    
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)appendText:(id)object
{
    NSString *text = [NSString stringWithFormat:@"%@", object];
    
    UIColor *textColor = toggleFlag ? [UIColor redColor] : [UIColor orangeColor];
    toggleFlag = !toggleFlag;
    
    NSAttributedString *appendText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", text]
                                                                     attributes:@{NSFontAttributeName:font,
                                                                                  NSForegroundColorAttributeName:textColor}];
    
    [debugLog appendAttributedString:appendText];
}

- (void)updateTextbox
{
    CGPoint p = [_textView contentOffset];
    
    _textView.attributedText = debugLog;
    
    if(shouldAutoScroll)
    {
        [_textView setContentOffset:p animated:NO];
        [_textView scrollRangeToVisible:NSMakeRange(_textView.attributedText.length, 0)];
    }
}

#pragma mark - UITextViewDelegate Methods

@end
