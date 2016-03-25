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
    self.title = @"Licenses";
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
}

#pragma mark - Helpers
- (void)setAndStyleTextViewsText
{
    NSString *newParagraph = @"\n\n\n\n";
    textView.tintColor = [AppEnvironmentConstants appTheme].mainGuiTint;
    
    NSMutableString *text = [[NSMutableString alloc] initWithString:@""];
    [text appendFormat:@"The following software has helped %@ ", MZAppName];
    [text appendFormat:@"get to where it is today:\n"];
    NSRange licenseIntro = NSMakeRange(0, text.length);
    int temp = (int)text.length;
    for(int i = 0; i < licenses.count; i++) {
        NSString *title = [((MZLicense *)licenses[i]).title removeIrrelevantWhitespace];
        [text appendFormat:@"\n• %@", title];
    }
    NSRange licenseBulletsSection = NSMakeRange(temp, text.length);
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
    [textView setText:text];
    float prefFontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    UIFont *introFont = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                        size:prefFontSize + 2];
    UIFont *regularFont = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                          size:prefFontSize];
    
    [textView.textStorage beginEditing];
    [textView.textStorage setAttributes:@{NSFontAttributeName : introFont}
                                  range:licenseIntro];
    [textView.textStorage setAttributes:@{NSFontAttributeName               : regularFont,
                                          NSForegroundColorAttributeName    : [UIColor grayColor]}
                                  range:licenseBulletsSection];
    
    //style the title for each license
    for(NSValue *val in titleRanges) {
        int titleFontSize = prefFontSize + 2;
        UIFont *boldFont = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                           size:titleFontSize];
        NSDictionary *dict = @{NSFontAttributeName : boldFont};
        [textView.textStorage setAttributes:dict range:[val rangeValue]];
    }
    
    //style the body for each license
    for(NSValue *val in bodyRanges) {
        NSDictionary *dict = @{NSFontAttributeName              : regularFont,
                               NSForegroundColorAttributeName   : [UIColor grayColor]};
        [textView.textStorage setAttributes:dict range:[val rangeValue]];
    }
    [textView.textStorage endEditing];
}

- (void)orientationDidChange
{
    textView.frame = self.view.frame;
}

@end
