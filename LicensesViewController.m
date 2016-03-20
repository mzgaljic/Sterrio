//
//  LicensesViewController.m
//  Sterrio
//
//  Created by Mark Zgaljic on 3/20/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "LicensesViewController.h"

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
        licenses = arrayOfMZLicenses;
    }
    return self;
}

- (void)dismiss
{
    licenses = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Licenses";
    textView = [[UITextView alloc] initWithFrame:self.view.frame];
    [textView setText:@"Testing..."];
    [self.view addSubview:textView];
}

@end
