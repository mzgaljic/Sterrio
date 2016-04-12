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
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@end
NSString * const TOS_LINK = @"https://dl.dropbox.com/s/3x5house6be4et4/Fabric%20TOS.pdf?dl=0";
#warning before releasing, put together a better PDF.

@implementation TermsOfServiceViewController

#pragma mark - Lifecyle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Terms Of Service";
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    self.webView = [[UIWebView alloc] initWithFrame:[self webViewFrame]];
    NSURL *targetURL = [NSURL URLWithString:TOS_LINK];
    NSURLRequest *request = [NSURLRequest requestWithURL:targetURL];
    self.webView.delegate = self;
    [self.webView loadRequest:request];
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
    self.webView.frame = [self webViewFrame];
    self.spinner.frame = [self spinnerFrame];
}

- (CGRect)webViewFrame
{
    int navBarHeight = [AppEnvironmentConstants navBarHeight];
    if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        return CGRectMake(0,
                          self.view.frame.origin.y + navBarHeight,
                          self.view.frame.size.width, self.view.frame.size.height - [AppEnvironmentConstants navBarHeight]);
    } else {
        navBarHeight = navBarHeight/2;
        return CGRectMake(0,
                          self.view.frame.origin.y + navBarHeight,
                          self.view.frame.size.width, self.view.frame.size.height - navBarHeight);
    }
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
