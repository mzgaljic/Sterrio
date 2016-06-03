//
//  AppRatingTableViewCell.m
//  Sterrio
//
//  Created by Mark Zgaljic on 2/20/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "AppRatingTableViewCell.h"
#import "SSBouncyButton.h"
#import "AppEnvironmentConstants.h"
#import "TOMSMorphingLabel.h"
#import "AppRatingUtils.h"
#import "EmailComposerManager.h"
#import "PreferredFontSizeUtility.h"

@interface AppRatingTableViewCell ()
{
    BOOL alreadySetupGuiElements;
    NSString *cachedTitleLabelText;
}
@property (nonatomic, strong) SSBouncyButton *yesBtn;
@property (nonatomic, strong) SSBouncyButton *notReallyBtn;
@property (nonatomic, strong) TOMSMorphingLabel *titleLabel;
@end

static const int Y_PADDING = 8;
static const int X_PADDING = 16;
static const int BUTTON_WIDTH = 120;
static const int IPHONE_4_WIDTH = 320;
static NSString * const RATE_US_ON_APP_STORE_TEXT = @"How about rating us on the App Store?";
static NSString * const GIVE_US_SOME_FEEDBACK_TEXT = @"Would you mind giving us some feedback?";
static NSString * const OK_SURE_TEXT = @"Ok, sure";
static NSString * const NO_THANKS_TEXT = @"No, thanks";

@implementation AppRatingTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    NSString *const orientationChangedNotif = UIApplicationDidChangeStatusBarOrientationNotification;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged)
                                                 name:orientationChangedNotif object:nil];
    alreadySetupGuiElements = NO;
}

- (void)dealloc
{
    _yesBtn = nil;
    _notReallyBtn = nil;
    _titleLabel = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
   
    if(alreadySetupGuiElements) {
        return;
    }
    [self initialAreYouLikingTheAppQuestion];
    alreadySetupGuiElements = YES;
}

- (void)initialAreYouLikingTheAppQuestion
{
    UIView *view = self.contentView;
    view.backgroundColor = [AppEnvironmentConstants appTheme].mainGuiTint;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    _titleLabel = [[TOMSMorphingLabel alloc] initWithFrame:[self titleLabelFrame]];
    _titleLabel.text = [NSString stringWithFormat:@"Enjoying %@?", MZAppName];
    cachedTitleLabelText = _titleLabel.text;
    _titleLabel.textColor = [AppEnvironmentConstants appTheme].navBarToolbarTextTint;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.animationDuration = 0.40;
    if(view.frame.size.width <= IPHONE_4_WIDTH) {
        _titleLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                           size:15];
    } else {
        _titleLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                           size:17];
    }
    
    _notReallyBtn = [[SSBouncyButton alloc] initWithFrame:[self noBtnFrame]];
    [_notReallyBtn setTitle:@"Not really" forState:UIControlStateNormal];
    [self applyNoStyleToSSButton:_notReallyBtn];
    [_notReallyBtn addTarget:self
                      action:@selector(noTapped)
            forControlEvents:UIControlEventTouchUpInside];
    

    _yesBtn = [[SSBouncyButton alloc] initWithFrame:[self yesBtnFrame]];
    [_yesBtn setTitle:@"Yes!" forState:UIControlStateNormal];
    [self applyYesStyleToSSButton:_yesBtn];
    [_yesBtn addTarget:self
                action:@selector(yesTapped)
      forControlEvents:UIControlEventTouchUpInside];
    
    [view addSubview:_titleLabel];
    [view addSubview:_notReallyBtn];
    [view addSubview:_yesBtn];
}

#pragma mark - Button actions
- (void)yesTapped
{
    if([_titleLabel.text isEqualToString:[NSString stringWithFormat:@"Enjoying %@?", MZAppName]]) {
        //now ask user if they want to rate the app now.
        _titleLabel.text = RATE_US_ON_APP_STORE_TEXT;
        cachedTitleLabelText = _titleLabel.text;
        [_yesBtn setTitle:OK_SURE_TEXT forState:UIControlStateNormal];
        [_notReallyBtn setTitle:NO_THANKS_TEXT forState:UIControlStateNormal];
        
    } else if([_titleLabel.text isEqualToString:RATE_US_ON_APP_STORE_TEXT]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MZHideAppRatingCell object:nil];
        [[AppRatingUtils sharedInstance] redirectToMyAppInAppStoreWithDelay:0.60];
    } else if([_titleLabel.text isEqualToString:GIVE_US_SOME_FEEDBACK_TEXT]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MZHideAppRatingCell object:nil];
        EmailComposerManager *mailComposer;
        mailComposer = [[EmailComposerManager alloc] initWithEmailComposePurpose:Email_Compose_Purpose_General_Feedback callingVc:[MZCommons topViewController]];
        [mailComposer presentEmailComposerAndOrPhotoPicker];
    }
}

- (void)noTapped
{
    if([_titleLabel.text isEqualToString:[NSString stringWithFormat:@"Enjoying %@?", MZAppName]]) {
        //user dislikes my app  :O   Ask for feedback.
        _titleLabel.text = GIVE_US_SOME_FEEDBACK_TEXT;
        cachedTitleLabelText = _titleLabel.text;
        [_yesBtn setTitle:OK_SURE_TEXT forState:UIControlStateNormal];
        [_notReallyBtn setTitle:NO_THANKS_TEXT forState:UIControlStateNormal];
        
    } else if([_titleLabel.text isEqualToString:GIVE_US_SOME_FEEDBACK_TEXT]){
        //user dislikes app and don't want to give
        //me feedback. Hide this cell and never show again.
        
        //comment this line if testing is desired.
        [AppEnvironmentConstants setUserHasRatedMyApp:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:MZHideAppRatingCell object:nil];
    } else if([_titleLabel.text isEqualToString:RATE_US_ON_APP_STORE_TEXT]) {
        //user doesn't want to rate even though they like app, hide cell and never show again.
        
        //comment this line if testing is desired.
        [AppEnvironmentConstants setUserHasRatedMyApp:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:MZHideAppRatingCell object:nil];
    }
}

#pragma mark - Orientation
- (void)orientationChanged
{
    //cachedTitleLabelText
    _titleLabel.frame = [self titleLabelFrame];
    _notReallyBtn.frame = [self noBtnFrame];
    _yesBtn.frame = [self yesBtnFrame];
}

#pragma mark - Util
- (void)applyYesStyleToSSButton:(SSBouncyButton *)btn
{
    btn.selected = YES;
    [btn setTitleColor:[AppEnvironmentConstants appTheme].mainGuiTint forState:UIControlStateSelected];
    btn.tintColor = [AppEnvironmentConstants appTheme].navBarToolbarTextTint;
    btn.titleLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                          size:btn.titleLabel.font.pointSize];
}

- (void)applyNoStyleToSSButton:(SSBouncyButton *)btn
{
    btn.selected = NO;
    btn.tintColor = [AppEnvironmentConstants appTheme].navBarToolbarTextTint;
    btn.titleLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                          size:btn.titleLabel.font.pointSize];
}

- (CGRect)titleLabelFrame
{
    int yMid = self.contentView.frame.size.height/2;
    int labelHeight = yMid - Y_PADDING - Y_PADDING;
    int titleEdgePadding = 5;
    return CGRectMake(titleEdgePadding,
                      Y_PADDING,
                      self.contentView.frame.size.width - (2 * titleEdgePadding),
                      labelHeight);
}

- (CGRect)yesBtnFrame
{
    int xMid = self.contentView.frame.size.width/2;
    int yMid = self.contentView.frame.size.height/2;
    int buttonHeight = yMid - Y_PADDING - Y_PADDING;
    return CGRectMake(xMid + X_PADDING,
                      yMid + Y_PADDING,
                      BUTTON_WIDTH,
                      buttonHeight);
}

- (CGRect)noBtnFrame
{
    int xMid = self.contentView.frame.size.width/2;
    int yMid = self.contentView.frame.size.height/2;
    int buttonHeight = yMid - Y_PADDING - Y_PADDING;
    return CGRectMake(xMid - X_PADDING - BUTTON_WIDTH,
                      yMid + Y_PADDING,
                      BUTTON_WIDTH,
                      buttonHeight);
}

@end
