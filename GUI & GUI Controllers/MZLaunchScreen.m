//
//  MZLaunchScreen.m
//  Sterrio
//
//  Created by Mark Zgaljic on 3/22/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZLaunchScreen.h"
#import "AppEnvironmentConstants.h"

@interface MZLaunchScreen ()
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@end

@implementation MZLaunchScreen

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spinner.frame = [self spinnerFrame];
    float scale = MZLargeSpinnerDownScaleAmount;
    self.spinner.transform = CGAffineTransformMakeScale(scale, scale);  //make smaller
    self.spinner.color = [AppEnvironmentConstants appTheme].contrastingTextColor;
    self.spinner.alpha = 0;
    [self.view addSubview:self.spinner];
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.spinner startAnimating];
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.spinner.alpha = 1;
                     }
                     completion:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

static MZLaunchScreen *retainSelf = nil;
- (void)dismissAnimatedAndDealloc
{
    retainSelf = self;
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.spinner.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [self.spinner stopAnimating];
                         [self.spinner removeFromSuperview];
                         self.spinner = nil;
                         //and after this line the retain cycle on MZLaunchScreen is broken,
                         //and if a new VC was added as the root VC, this class will be dealloced.
                         retainSelf = nil;
                     }];
}

#pragma mark - Utils
- (void)orientationDidChange
{
    self.spinner.frame = [self spinnerFrame];
}

- (CGRect)spinnerFrame
{
    CGRect viewFrame = self.view.frame;
    int indicatorSize = self.spinner.frame.size.width;
    return CGRectMake(viewFrame.size.width/2 - indicatorSize/2,
                      viewFrame.size.height/2 - indicatorSize/2,
                      indicatorSize,
                      indicatorSize);
}

@end
