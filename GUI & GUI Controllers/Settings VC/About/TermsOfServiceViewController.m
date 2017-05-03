//
//  TermsOfServiceViewController.m
//  Sterrio
//
//  Created by Mark Zgaljic on 3/20/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "TermsOfServiceViewController.h"
#import "AppEnvironmentConstants.h"

@interface TermsOfServiceViewController ()
//@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@end

@implementation TermsOfServiceViewController
#pragma mark - Lifecyle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Terms & Conditions";
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:MZAppTermsPdfLink]];
    self.webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    self.webView.delegate = self;
    [self.webView loadRequest:request];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.webView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    float scale = MZLargeSpinnerDownScaleAmount;
    self.spinner.transform = CGAffineTransformMakeScale(scale, scale);  //make smaller
    self.spinner.frame = [self spinnerFrame];
    self.spinner.color = [AppEnvironmentConstants appTheme].contrastingTextColor;
    [self.spinner startAnimating];
    [self.view addSubview:self.spinner];
}

- (void)dealloc
{
    self.webView = nil;
    self.spinner = nil;
}

#pragma mark - UIWebView Delegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.spinner stopAnimating];
    [self.spinner removeFromSuperview];
    self.spinner = nil;
}

#pragma mark - GUI
- (void)dismiss
{
    [self.webView stopLoading];
    self.webView.delegate = nil;
    [self.spinner stopAnimating];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Utils
- (void)orientationDidChange
{
    self.spinner.frame = [self spinnerFrame];
}

- (CGRect)spinnerFrame
{
    CGRect screenFrame = [UIScreen mainScreen].bounds;
    int indicatorSize = self.spinner.frame.size.width;
    return CGRectMake(screenFrame.size.width/2 - indicatorSize/2,
                      screenFrame.size.height/2 - indicatorSize/2,
                      indicatorSize,
                      indicatorSize);
}

@end
