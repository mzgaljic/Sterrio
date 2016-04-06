//
//  LicensesViewController.m
//  Sterrio
//
//  Created by Mark Zgaljic on 3/20/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "LicensesViewController.h"
#import "MZLicense.h"
#import "PreferredFontSizeUtility.h"
#import "NSString+WhiteSpace_Utility.h"

@interface LicensesViewController ()
{
    NSArray *licenses;
    UITextView *textView;
}
@end

@implementation LicensesViewController

- (instancetype)initWithLicenses:(NSArray *)arrayOfMZLicenses
{
    if(self = [super init]) {
        NSArray *sortedArray;
        sortedArray = [arrayOfMZLicenses sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSString *first = [(MZLicense*)a title];
            NSString *second = [(MZLicense*)b title];
            return [first compare:second];
        }];
        licenses = sortedArray;
        arrayOfMZLicenses = nil;
    }
    return self;
}

- (void)dismiss
{
    licenses = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Credits & Licenses";
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    textView = [[UITextView alloc] initWithFrame:self.view.frame];
    textView.editable = NO;
    [self setAndStyleTextViewsText];
    [self.view addSubview:textView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //due to how the UITextView is created and customized in ViewDidLoad, we need to scroll
    //to the top before the user starts using it. Otherwise it doesn't quite start where it should.
    CGPoint desiredOffset = CGPointMake(0, -textView.contentInset.top);
    [textView setContentOffset:desiredOffset animated:NO];
    [textView setSelectable:NO];
}

#pragma mark - Helpers
- (void)setAndStyleTextViewsText
{
    int temp = -1;
    NSString *newParagraph = @"\n\n\n\n";
    textView.tintColor = [AppEnvironmentConstants appTheme].mainGuiTint;
    
    NSMutableString *text = [[NSMutableString alloc] initWithString:@""];
    temp = (int)text.length;
    [text appendString:@"Credits\n\n"];
    NSRange creditsTitleRange = NSMakeRange(temp, text.length - temp);
    temp = (int)text.length;
    [text appendFormat:@"A special thank you to my girlfriend Sharanne for putting up with all the time I spent working on %@.\n\n", MZAppName];
    NSRange thanksSharanneRange = NSMakeRange(temp, text.length - temp);
    temp = (int)text.length;
    [text appendString:@"Icon Designer: Luca Burgio\n\n\n\n"];
    NSRange iconDesignerRange = NSMakeRange(temp, text.length - temp);
    temp = (int)text.length;
    [text appendString:@"Licenses"];
    NSRange licensesTitleRange = NSMakeRange(temp, @"Licenses".length);
    temp = (int)text.length;
    [text appendFormat:@"\n\nThe following software has helped %@ get to where it is today:\n",MZAppName];
    NSRange licenseIntro = NSMakeRange(temp, text.length - temp);
    temp = (int)text.length;
    
    for(int i = 0; i < licenses.count; i++) {
        NSString *title = [((MZLicense *)licenses[i]).title removeIrrelevantWhitespace];
        [text appendFormat:@"\n• %@", title];
    }
    NSRange licenseBulletsSection = NSMakeRange(temp, text.length - temp);
    [text appendString:newParagraph];
    
    NSMutableArray *titleRanges = [NSMutableArray arrayWithCapacity:licenses.count];
    NSMutableArray *bodyRanges = [NSMutableArray arrayWithCapacity:licenses.count];
    for(int i = 0; i < licenses.count; i++) {
        NSString *title = [((MZLicense *)licenses[i]).title removeIrrelevantWhitespace];
        NSString *body = [((MZLicense *)licenses[i]).body removeIrrelevantWhitespace];
        
        if(i != 0) {
            [text appendString:newParagraph];
        }
        [titleRanges addObject:[NSValue valueWithRange:NSMakeRange(text.length, title.length)]];
        [text appendFormat:@"%@\n", title];
        [bodyRanges addObject:[NSValue valueWithRange:NSMakeRange(text.length, body.length)]];
        [text appendString:body];
    }
    
    [text appendString:newParagraph];
    temp = (int)text.length;
    [text appendString:@"Image Credits"];
    NSRange imageCreditsTitleRange = NSMakeRange(temp, @"Image Credits".length);
    [text appendString:@"\n"];
    temp = (int)text.length;
    [text appendString:[self imageCreditsText]];
    NSRange imageCreditsRange = NSMakeRange(temp, text.length - temp);
    [textView setText:text];
    
    float prefFontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    UIFont *introFont = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                        size:prefFontSize + 2];
    UIFont *regularFont = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                          size:prefFontSize];
    UIFont *boldFont = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                       size:prefFontSize + 2];
    
    //Customize the look and feel (alignment, colors, fonts, etc.)
    [textView.textStorage beginEditing];
    
    //Make 'Credits' title centered and bold.
    NSMutableParagraphStyle *centerAlignStyle = [NSMutableParagraphStyle new];
    [centerAlignStyle setAlignment:NSTextAlignmentCenter];
    [textView.textStorage addAttributes:@{NSFontAttributeName : boldFont}
                                  range:creditsTitleRange];
    [textView.textStorage addAttributes:@{NSParagraphStyleAttributeName : centerAlignStyle}
                                  range:creditsTitleRange];
    
    //Make 'Licenses' title centered and bold
    [textView.textStorage addAttributes:@{NSFontAttributeName : boldFont}
                                  range:licensesTitleRange];
    [textView.textStorage addAttributes:@{NSParagraphStyleAttributeName : centerAlignStyle}
                                  range:licensesTitleRange];
    
    //Make 'Image Credits' title centered and bold
    [textView.textStorage addAttributes:@{NSFontAttributeName : boldFont}
                                  range:imageCreditsTitleRange];
    [textView.textStorage addAttributes:@{NSParagraphStyleAttributeName : centerAlignStyle}
                                  range:imageCreditsTitleRange];
    
    [textView.textStorage addAttributes:@{NSFontAttributeName : introFont}
                                  range:thanksSharanneRange];
    [textView.textStorage addAttributes:@{NSFontAttributeName : introFont}
                                  range:iconDesignerRange];
    [textView.textStorage addAttributes:@{NSFontAttributeName : introFont}
                                  range:licenseIntro];
    [textView.textStorage addAttributes:@{NSFontAttributeName               : regularFont,
                                          NSForegroundColorAttributeName    : [UIColor grayColor]}
                                  range:licenseBulletsSection];
    
    //style the title for each license
    for(NSValue *val in titleRanges) {
        NSDictionary *dict = @{NSFontAttributeName : boldFont};
        [textView.textStorage addAttributes:dict range:[val rangeValue]];
    }
    
    //style the body for each license
    for(NSValue *val in bodyRanges) {
        NSDictionary *dict = @{NSFontAttributeName              : regularFont,
                               NSForegroundColorAttributeName   : [UIColor grayColor]};
        [textView.textStorage addAttributes:dict range:[val rangeValue]];
    }
    [textView.textStorage addAttributes:@{NSFontAttributeName              : regularFont,
                                          NSForegroundColorAttributeName   : [UIColor grayColor]}
                                  range:imageCreditsRange];
    [textView.textStorage endEditing];
}

- (NSString *)imageCreditsText
{
    NSMutableString *text = [[NSMutableString alloc] initWithString:textView.text];
    //Tab Bar
    [text appendString:@"\nSongs Tab: \n"];
    [text appendString:@"Albums Tab: \n"];
    [text appendString:@"Artists Tab: \n"];
    [text appendString:@"Playlist Tab: \n"];
    [text appendString:@"'Add' Tab Bar Button: \n"];
    
    //Player VC
    [text appendString:@"Sleep Timer: \n"];
    [text appendString:@"Playback Queue: \n"];
    
    //miscellaneous stuff throughout the app
    [text appendString:@"Airplay: \n"];
    [text appendString:@"Swipe-up video hint: \n"];
    
    //UIBarButtonItem's on nav bars
    [text appendString:@"Settings: \n"];
    
    //Settings page
    [text appendString:@"iCloud Setting: \n"];
    [text appendString:@"Cellular Video Quality Setting: \n"];
    [text appendString:@"WiFi Video Quality Setting: \n"];
    [text appendString:@"App Theme Setting: \n"];
    [text appendString:@"Advanced Setting: \n"];
    return text;
}

- (void)orientationDidChange
{
    textView.frame = self.view.frame;
}

@end
