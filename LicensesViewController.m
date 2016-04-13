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
    textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
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
    [text appendFormat:@"%@ Icon Designer: Luca Burgio", MZAppName];
    NSRange iconDesignerRange = NSMakeRange(temp, text.length - temp);
    temp = (int)text.length;
    [text appendString:@"\nMore image credits below...\n\n\n"];
    NSRange otherImageCreditsTextRange = NSMakeRange(temp, text.length - temp);
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
    [textView.textStorage addAttributes:@{NSForegroundColorAttributeName    : [UIColor grayColor],
                                          NSFontAttributeName               : regularFont}
                                  range:otherImageCreditsTextRange];
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
    [text appendString:@"\nCreative Commons 2.5 License:\nhttp://creativecommons.org/licenses/by/2.5/\n\n"];
    [text appendString:@"Creative Commons 3.0 License:\nhttp://creativecommons.org/licenses/by-sa/3.0/us/"];
    
    //Tab Bar
    [text appendString:@"\n\n•Songs Tab:\nJoseph Wain, http://glyphish.com"];
    [text appendString:@"\n\n•Albums Tab:\nSergei Kokota, http://goo.gl/sk08jX - (modified)"];
    [text appendString:@"\n\n•Playlist Tab:\nJoseph Wain, http://glyphish.com"];
    [text appendString:@"\n\n•'Add' Tab Bar Button:\nMagnus Emil Liisberg Helding, http://goo.gl/4ZqVXH"];
    
    //Player VC
    [text appendString:@"\n\n•Sleep Timer:\nJoseph Wain, http://glyphish.com"];
    [text appendString:@"\n\n•Playback Queue:\nJoseph Wain, http://glyphish.com"];
    
    //miscellaneous stuff throughout the app
    [text appendString:@"\n\n•Airplay:\nIcojamView, http://goo.gl/s3D67t"];
    [text appendString:@"\n\n•Swipe-up video hint:\n GestureWorks, http://goo.gl/wxwYvA - CC 3.0 (unmodified)"];
    
    //UIBarButtonItem's on nav bars
    [text appendString:@"\n\n•Settings:\nJayson Lane, http://jlane.co/ios-8-line-icons/"];
    
    //Settings page
    [text appendString:@"\n\n•iCloud Setting:\nJoseph Wain, http://glyphish.com"];
    [text appendString:@"\n\n•Cellular Quality Setting:\nCreative Stall, http://goo.gl/AIAxk4"];
    [text appendString:@"\n\n•WiFi Quality Setting:\nJayson Lane, http://jlane.co/ios-8-line-icons/"];
    [text appendString:@"\n\n•App Theme Setting:\nSergei Kokota, http://goo.gl/XzaOSm - CC 2.5 (unmodified)"];
    [text appendString:@"\n\n•Advanced Setting:\nDesign Revision, http://goo.gl/l80dr6"];
    return text;
}

- (void)orientationDidChange
{
    //textView.frame = self.view.frame;
}

@end
