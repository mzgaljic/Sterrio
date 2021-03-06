//
//  MainScreenViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MainScreenViewController.h"
#import "PushNotificationsHelper.h"
#import "TermsOfServiceViewController.h"

NSString * const CENTER_BTN_IMG_NAME = @"plus_sign";
short const dummyTabIndex = 2;

@interface MainScreenViewController()
{
    //used to avoid a blank screen on initial launch when calling
    //'replaceNavControllerOnScreenWithNavController'
    NSUInteger numTimesViewHasAppeared;
    
    BOOL alwaysKeepStatusBarInvisible;
    BOOL tabBarAnimationInProgress;
    BOOL changingTabs;
    BOOL prevAdsRemovedValue;
    UIInterfaceOrientation lastVisibleTabBarOrientation;
    NSUInteger heightOfAdBanner;
}
@property (nonatomic, strong) UIImage *centerButtonImg;
@property (nonatomic, strong) GADBannerView *adBanner;
@property (nonatomic, strong) UIActivityIndicatorView *adBannerSpinner;
@property (nonatomic, strong) UIView *tabBarView;  //contains the tab bar and center button - the whole visual thing.
@property (nonatomic, strong) UITabBar *tabBar;  //this tab bar is containing within a tab bar view
@property (nonatomic, strong) SSBouncyButton *centerButton;
@property (nonatomic, strong) NSArray *navControllers;
@property (nonatomic, strong) NSArray *viewControllers;
@property (nonatomic, strong) NSArray *tabBarUnselectedImageNames;
@property (nonatomic, strong) NSArray *tabBarSelectedImageNames;
@property (nonatomic, strong) NSArray *tabBarItems;
@property (nonatomic, strong) UINavigationController *currentNavController;

@property (nonatomic, strong) NSMutableDictionary *tabsNeedingForcedDataReload;
@end


@implementation MainScreenViewController

#pragma mark - ViewController Lifecycle
- (instancetype)initWithNavControllers:(NSArray *)navControllers
          correspondingViewControllers:(NSArray *)viewControllers
            tabBarUnselectedImageNames:(NSArray*)unSelectNames
              tabBarselectedImageNames:(NSArray*)selectNames
{
    if(self = [super init]){
        self.navControllers = navControllers;
        self.viewControllers = viewControllers;
        self.tabBarUnselectedImageNames = unSelectNames;
        self.tabBarSelectedImageNames = selectNames;
        [[UITabBar appearance] setTintColor:[[AppEnvironmentConstants appTheme].mainGuiTint lighterColor]];
        numTimesViewHasAppeared = 0;
        [AppEnvironmentConstants setTabBarHidden:NO];
        tabBarAnimationInProgress = NO;
        changingTabs = NO;
        prevAdsRemovedValue = [AppEnvironmentConstants areAdsRemoved];
        [AppEnvironmentConstants setBannerAdHeight:0];
        _tabsNeedingForcedDataReload = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.adBanner.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.currentNavController = self.navControllers[0];
    self.view.backgroundColor = [UIColor clearColor];
    NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];
    [notifCenter addObserver:self
                    selector:@selector(portraitStatusBarStateChanging:)
                        name:MZMainScreenVCStatusBarAlwaysInvisible
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(hideTabBarAnimated:)
                        name:MZHideTabBarAnimated
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(appThemePossiblyChanged)
                        name:@"app theme color has possibly changed"
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(userDoneWithIntroAndTermsAccepted)
                        name:MZAppIntroCompleteAndAppTermsAccepted object:nil];
    [notifCenter addObserver:self
                    selector:@selector(newSongIsLoading:)
                        name:MZNewSongLoading
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(dismissPlayerExpandingTip:)
                        name:@"shouldDismissPlayerExpandingTip"
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(appBecomingActiveAgain)
                        name:UIApplicationDidBecomeActiveNotification
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(everyTabWillNeedAForcedReload)
                        name:MZForceMainVcTabsToUpdateDatasources
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(expandedPlayerIsShrinking)
                        name:MZExpandedPlayerIsShrinking
                      object:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if([AppEnvironmentConstants appTheme].useWhiteStatusBar) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

//this is called when Sterrio itself is hiding and showing the status bar. this is NOT called
//when the status bar expanded and contracts, that's a totally separate thing.
- (void)portraitStatusBarStateChanging:(NSNotification *)notification
{
    alwaysKeepStatusBarInvisible = [(NSNumber *)notification.object boolValue];
    [UIView animateWithDuration:0.35 animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if([AppEnvironmentConstants areAdsRemoved] && self.adBanner) {
        self.adBanner.delegate = nil;
        self.adBanner = nil;
    } else if(! [AppEnvironmentConstants areAdsRemoved] && self.adBanner) {
        //get new ad.
        [self.adBanner loadRequest:[MZCommons getNewAdmobRequest]];
    }
    
    if(numTimesViewHasAppeared != 0) {
        [self replaceNavControllerOnScreenWithNavController:self.currentNavController];
    } else {
        //initial launch...replaceNavController method optimizes and checks if the viewcontrollers
        //match. need to avoid the optimization the first time. setting current nav controller too.
        self.currentNavController = nil;
        [self replaceNavControllerOnScreenWithNavController:self.navControllers[0]];
    }
    numTimesViewHasAppeared++;
    
    [self setupTabBarAndTabBarView];
    if(self.tabBarItems == nil) {
        [self createTabBarItems];
    }
    
    [self setTabBarItems];
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSInteger highestTosVerUserAccepted = [[AppEnvironmentConstants highestTosVersionUserAccepted] integerValue];
    long long numAppLaunches = [AppEnvironmentConstants numberTimesUserLaunchedApp].longLongValue;
    
    //only ask for push notifications if user launched the app at least once AND they
    //accepted the current TOS. Will only show dialog if they didn't previously accept/decline.
    if(numAppLaunches >= 2 && highestTosVerUserAccepted == MZCurrentTosVersion) {
        [PushNotificationsHelper askUserIfTheyAreInterestedInPushNotif];
    }
    if(![AppEnvironmentConstants isFirstTimeAppLaunched]
       && highestTosVerUserAccepted != MZCurrentTosVersion) {
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_NEWTosAndPrivacyPolicy];
    }
}

//this method fixes a bug where the tab bar would look screwed up mid-call (hard to reproduce)
- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    //these checks are needed since viewWillLayoutSubviews is called A LOT. The code in here
    //is 'expensive' and a waste. This method is how the tab bar 'fixes' its frame when the
    //user is in a call or using google maps (status bar height expands).
    if(! changingTabs) {
        float duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
        [UIView animateWithDuration:duration
                         animations:^{
                                     [self setupTabBarAndTabBarViewUsingOrientation:[UIApplication sharedApplication].statusBarOrientation];
        }];

        int subFromY = 0;
        if([AppEnvironmentConstants isTabBarHidden]) {
            //weird ass logic that helps place the ad banner correctly when the user is in a
            //detail VC (and tab bar isn't visible.)
            subFromY = 50;
        }
        [UIView animateWithDuration:duration
                         animations:^{
                             self.adBanner.frame = CGRectMake(0,
                                                              self.tabBarView.frame.origin.y + self.tabBarView.frame.size.height - subFromY,
                                                              self.adBanner.frame.size.width,
                                                              self.adBanner.frame.size.height);
        }];
    }
    
    changingTabs = NO;
}

static NSTimeInterval prevAppBecameActiveTimeInterval = 0;
- (void)appBecomingActiveAgain
{
    if([AppEnvironmentConstants areAdsRemoved] && self.adBanner) {
        return;
    }
    if(prevAppBecameActiveTimeInterval == 0) {
        prevAppBecameActiveTimeInterval = [NSDate timeIntervalSinceReferenceDate];
    } else {
        NSTimeInterval oldInterval = prevAppBecameActiveTimeInterval;
        NSTimeInterval newInterval = [NSDate timeIntervalSinceReferenceDate];
        prevAppBecameActiveTimeInterval = newInterval;
        if(newInterval - oldInterval <= 20) {
            //don't want to show ad on app resume if the last app resume was within 30 seconds.
            return;
        }
    }
    //app not about to launch, and the this VC is visible on screen.
    if(numTimesViewHasAppeared != 0 && self.isViewLoaded && self.view.window) {
        if(! [AppEnvironmentConstants areAdsRemoved] && self.adBanner) {
            //get new ad.
            [self.adBanner loadRequest:[MZCommons getNewAdmobRequest]];
        }
    }
}

#pragma mark - Tab bar delegates
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    int tabIndex = (int)[[tabBar items] indexOfObject:item];
    int visualTabIndex = tabIndex;
    if(tabIndex > dummyTabIndex)
        visualTabIndex--;
    [self replaceNavControllerOnScreenWithNavController:self.navControllers[visualTabIndex]];
}

#pragma mark - GUI helpers
- (void)replaceNavControllerOnScreenWithNavController:(UINavigationController *)newNavController
{
    [self forceUpdateVcDataSourceIfNecessary:newNavController];
    
    BOOL adsRemoved = [AppEnvironmentConstants areAdsRemoved];
    if(adsRemoved == prevAdsRemovedValue && self.currentNavController == newNavController) {
        return;
    }
    
    adsRemoved = [AppEnvironmentConstants areAdsRemoved];
    BOOL oldNavBarHidden = self.currentNavController.navigationBarHidden;
    [newNavController setNavigationBarHidden:oldNavBarHidden animated:NO];
    changingTabs = YES;
    
    //VC lifecycle methods not being called, i fix that here...
    NSUInteger index = [self.navControllers indexOfObjectIdenticalTo:self.currentNavController];
    UIViewController *oldVc;
    if(index != NSNotFound)
        oldVc = self.viewControllers[index];
    [oldVc viewWillDisappear:YES];
    [oldVc.navigationController.view removeFromSuperview];
    [oldVc viewDidDisappear:YES];
    [oldVc.navigationController removeFromParentViewController];
    
    if(! adsRemoved && self.adBanner == nil) {
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        GADBannerView *adBanner = nil;
        if(UIInterfaceOrientationIsPortrait(orientation)) {
            adBanner = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];
        } else {
            adBanner = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerLandscape];
        }
        adBanner.delegate = self;
        
        adBanner.rootViewController = self;
        adBanner.adUnitID = MZAdMobUnitId;
        
        heightOfAdBanner = adBanner.frame.size.height;
        [AppEnvironmentConstants setBannerAdHeight:(int)heightOfAdBanner];
        int yStartOfAdBanner = self.view.frame.size.height - heightOfAdBanner;
        adBanner.alpha = 0;
        adBanner.frame = CGRectMake(0, yStartOfAdBanner, adBanner.frame.size.width, adBanner.frame.size.height);
        //get the ad
        [adBanner loadRequest:[MZCommons getNewAdmobRequest]];
        [self.view addSubview:adBanner];
        self.adBanner = adBanner;
        
        //set up spinner so it doesn't look as ugly
        UIView *spinnerView = [[UIView alloc] initWithFrame:adBanner.frame];
        [self.view addSubview:spinnerView];
        spinnerView.backgroundColor = [UIColor whiteColor];
        self.adBannerSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        UIActivityIndicatorView *spinner = self.adBannerSpinner;
        float indicatorSize = self.adBannerSpinner.frame.size.width;
        spinner.frame = CGRectMake(self.view.frame.size.width/2 - indicatorSize/2,
                                   (adBanner.frame.size.height / 2.0) - (indicatorSize/2),
                                   indicatorSize,
                                   indicatorSize);
        spinner.tintColor = [AppEnvironmentConstants appTheme].contrastingTextColor;
        [spinner startAnimating];
        [spinnerView addSubview:spinner];
    }
    
    if(adsRemoved == YES && prevAdsRemovedValue == NO) {
        heightOfAdBanner = 0;
        [self.adBanner removeFromSuperview];
    }
    
    //containing the nav controller within a container
    CGRect desiredVcFrame = CGRectMake(0,
                                       0,
                                       self.view.frame.size.width,
                                       self.view.frame.size.height - heightOfAdBanner);
    [self addChildViewController:newNavController];
    newNavController.view.frame = desiredVcFrame;
    
    index = [self.navControllers indexOfObjectIdenticalTo:newNavController];
    UIViewController *newVc = self.viewControllers[index];

    [newVc viewWillAppear:YES];
    [self.view addSubview:newNavController.view];
    //make sure tab bar is not covered by the new nav controllers view
    [self.view insertSubview:self.tabBarView aboveSubview:self.view];
    
    [newNavController didMoveToParentViewController:self];
    [newVc viewDidAppear:YES];
    [UIView animateWithDuration:0.35 animations:^{
        [newVc setNeedsStatusBarAppearanceUpdate];
    }];
    
    self.currentNavController = newNavController;
    
    //init these constants only once.
    if(! newNavController.navigationBarHidden && [AppEnvironmentConstants statusBarHeight] == 0){
        int statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        [AppEnvironmentConstants setStatusBarHeight:statusBarHeight];
    }
}

//general setup when not rotating the screen
- (void)setupTabBarAndTabBarView
{
    [self forceTabBarToRedrawFromScratch];
}

//helper for setupTabBarAndTabBarView, and used for screen rotation
- (void)setupTabBarAndTabBarViewUsingOrientation:(UIInterfaceOrientation)orientation
{
    if(self.tabBarView == nil){
        self.tabBarView = [[UIView alloc] init];
        
        self.tabBar = [[UITabBar alloc] init];
        [self.tabBar setTranslucent:YES];
        self.tabBar.delegate = self;
        
        self.centerButtonImg = [MZCommons centerButtonImage];
        self.centerButton = [[SSBouncyButton alloc] initAsImage];
        [self.centerButton setImage:self.centerButtonImg forState:UIControlStateNormal];
        [self.centerButton setHitTestEdgeInsets:UIEdgeInsetsMake(-10, -10, -10, -10)];
        [self.centerButton addTarget:self action:@selector(centerButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if(UIInterfaceOrientationIsLandscape(orientation))
        self.tabBarView.frame = [self landscapeTabBarViewFrame];
    else
        self.tabBarView.frame = [self portraitTabBarViewFrame];
    
    if([AppEnvironmentConstants isTabBarHidden]){
        self.tabBarView.frame = CGRectMake(self.tabBarView.frame.origin.x,
                                           self.tabBarView.frame.origin.y + MZTabBarHeight,
                                           self.tabBarView.frame.size.width,
                                           self.tabBarView.frame.size.height);
    }
    
    
    self.tabBar.frame = CGRectMake(0, 0, self.tabBarView.frame.size.width, self.tabBarView.frame.size.height);
    self.centerButton.frame = [self centerBtnFrameGivenTabBarViewFrame:self.tabBarView.frame
                                                          centerBtnImg:self.centerButtonImg];

    [self.tabBarView addSubview:self.tabBar];
    [self.tabBarView addSubview:self.centerButton];
    [self.tabBarView setMultipleTouchEnabled:NO];
    
    if(! [AppEnvironmentConstants isTabBarHidden]){
        lastVisibleTabBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        if(! self.tabBarView.superview) {
            self.tabBarView.alpha = 0;
            [self.view addSubview:self.tabBarView];
        }
        
        [UIView animateWithDuration:0.4
                              delay:0
                            options:UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                                self.tabBarView.alpha = 1;
                         } completion:nil];
    }
}

- (void)setTabBarItems
{
    UITabBarItem *selectedItem = [self.tabBar selectedItem];
    if(selectedItem == nil)  //setting default
        selectedItem = self.tabBarItems[0];
    [self.tabBar setItems:self.tabBarItems animated:NO];
    [self.tabBar setSelectedItem:selectedItem];
}

- (void)createTabBarItems
{
    NSMutableArray *tabBarItems = [NSMutableArray array];
    UITabBarItem *someItem;
    UIImage *unselectedImg;
    UIImage *selectedImg;
    NSString *unselectedImgFileName;
    NSString *selectedImgFileName;
    UINavigationController *aNavController;
    //the index in the loop when we need to create the dummy tab bar item
    //(dummy tab bar item will be exactly under our custom uibutton in the
    //superview...the tabBarView)
    short fakeTabIndex = dummyTabIndex;
    for(int i = 0; i < self.navControllers.count; i++){
        if(fakeTabIndex == i){
            [tabBarItems addObject:[[UITabBarItem alloc] initWithTitle:@"" image:nil selectedImage:nil]];
        }
        aNavController = self.navControllers[i];
        unselectedImgFileName = self.tabBarUnselectedImageNames[i];
        selectedImgFileName = self.tabBarSelectedImageNames[i];
        if(unselectedImgFileName.length > 0)  //not needed but faster since program doesnt need to check assets.
            unselectedImg = [UIImage imageNamed:unselectedImgFileName];
        if(selectedImgFileName.length > 0)
            selectedImg = [UIImage imageNamed:selectedImgFileName];
        someItem = [[UITabBarItem alloc] initWithTitle:aNavController.title image:unselectedImg selectedImage:selectedImg];
        [tabBarItems addObject:someItem];
        unselectedImgFileName = nil;
        unselectedImg = nil;
        someItem = nil;
    }
    self.tabBarItems = tabBarItems;
}

- (CGRect)portraitTabBarViewFrame
{
    float portraitWidth;
    float portraitHeight;
    float  a = self.view.frame.size.height;
    float b = self.view.frame.size.width;
    if(a < b){
        portraitHeight = b;
        portraitWidth = a;
    }else{
        portraitWidth = b;
        portraitHeight = a;
    }
    
    //the +1 at the end fixes a weird bug where the tableview underneath the tab bar
    //would be visible in an ugly way if the user is on ios7 & sees the adbanner.
    int yVal = portraitHeight - heightOfAdBanner - MZTabBarHeight + 1;
    return CGRectMake(0, yVal, portraitWidth, MZTabBarHeight);
}

- (CGRect)landscapeTabBarViewFrame
{
    float landscapeWidth;
    float landscapeHeight;
    float  a = [[UIScreen mainScreen] bounds].size.height;
    float b = [[UIScreen mainScreen] bounds].size.width;
    if(a < b){
        landscapeWidth = b;
        landscapeHeight = a;
    }else{
        landscapeHeight = b;
        landscapeWidth = a;
    }
    
    //the +1 at the end fixes a weird bug where the tableview underneath the tab bar
    //would be visible in an ugly way if the user is on ios7 & sees the adbanner.
    int yVal = landscapeHeight - heightOfAdBanner - MZTabBarHeight + 1;
    return CGRectMake(0, yVal, landscapeWidth, MZTabBarHeight);
}

- (CGRect)centerBtnFrameGivenTabBarViewFrame:(CGRect)tabBarViewFrame centerBtnImg:(UIImage *)img
{
    short centerBtnDiameter = img.size.height;  //same diameter in either dimension
    return CGRectMake((tabBarViewFrame.size.width/2) - (centerBtnDiameter/2),
                      ((tabBarViewFrame.size.height)/2) - (centerBtnDiameter/2),
                      centerBtnDiameter,
                      centerBtnDiameter);
}

- (void)hideTabBarAnimated:(NSNotification *)notification
{
    NSNumber *boolAsNum = [notification object];
    BOOL hide = [boolAsNum boolValue];
    CGRect visibleRect;
    UIInterfaceOrientation currentInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if(UIInterfaceOrientationIsPortrait((currentInterfaceOrientation)))
        visibleRect = [self portraitTabBarViewFrame];
    else
        visibleRect = [self landscapeTabBarViewFrame];
    
    float hideDuration = 0.5;
    float showDuration = 0.35;
    float delay = 0;
    float springDamping = 0.90;
    float initialHideVelocity = 0.35;
    float initialShowVelocity = 0.9;
    
    if(hide)
    {
        if([AppEnvironmentConstants isTabBarHidden])
            return;
        [AppEnvironmentConstants setTabBarHidden:YES];
        lastVisibleTabBarOrientation = currentInterfaceOrientation;
        CGRect hiddenFrame = CGRectMake(visibleRect.origin.x,
                                        visibleRect.origin.y + MZTabBarHeight,
                                        visibleRect.size.width,
                                        visibleRect.size.height);
        [UIView animateWithDuration:hideDuration
                              delay:delay
             usingSpringWithDamping:springDamping
              initialSpringVelocity:initialHideVelocity
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self.tabBarView setFrame:hiddenFrame];
                             self.tabBarView.alpha = 0;
                         }
                         completion:^(BOOL finished) {
                             [AppEnvironmentConstants setTabBarHidden:YES];
                             tabBarAnimationInProgress = NO;
                         }];
    }
    else
    {
        if(! [AppEnvironmentConstants isTabBarHidden])
            return;
        [AppEnvironmentConstants setTabBarHidden:NO];
        //checking if orientations have changed (meaningfully anyway...as far as needing to redraw the tab bar)
        if(! (UIInterfaceOrientationIsPortrait(lastVisibleTabBarOrientation)
              && UIInterfaceOrientationIsPortrait(currentInterfaceOrientation))
           ||
           ! (UIInterfaceOrientationIsLandscape(lastVisibleTabBarOrientation)
            && UIInterfaceOrientationIsLandscape(currentInterfaceOrientation)))
        {
            [self forceTabBarToRedrawFromScratch];
            [self.tabBarView setFrame:CGRectMake(self.tabBarView.frame.origin.x,
                                                 self.tabBarView.frame.origin.y + MZTabBarHeight,
                                                 self.tabBarView.frame.size.width,
                                                 self.tabBarView.frame.size.height)];
        }
        
        [UIView animateWithDuration:showDuration
                              delay:delay
             usingSpringWithDamping:springDamping + 0.1
              initialSpringVelocity:initialShowVelocity
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self.tabBarView setFrame:visibleRect];
                              self.tabBarView.alpha = 1;
                         }
                         completion:^(BOOL finished) {
                             [AppEnvironmentConstants setTabBarHidden:NO];
                             tabBarAnimationInProgress = NO;
                         }];
    }
}

- (void)updateAdBannerForOrientation:(UIInterfaceOrientation)orientation
{
    if([AppEnvironmentConstants areAdsRemoved]){
        return;
    }
    
    //remove spinner if it's on screen
    if(self.adBannerSpinner) {
        UIView *spinnerView = self.adBannerSpinner.superview;
        [self.adBannerSpinner stopAnimating];
        [self.adBannerSpinner removeFromSuperview];
        [spinnerView removeFromSuperview];
        spinnerView = nil;
    }

    GADBannerView *adBanner = self.adBanner;
    if(UIInterfaceOrientationIsLandscape(orientation)) {
        adBanner.adSize = kGADAdSizeSmartBannerLandscape;
    } else {
        adBanner.adSize = kGADAdSizeSmartBannerPortrait;
    }
    heightOfAdBanner = adBanner.frame.size.height;
    [AppEnvironmentConstants setBannerAdHeight:(int)heightOfAdBanner];
    int yStartOfAdBanner = self.view.frame.size.width - heightOfAdBanner;
    adBanner.frame = CGRectMake(0, yStartOfAdBanner, adBanner.frame.size.width, adBanner.frame.size.height);
    [self.adBanner removeFromSuperview];
    self.adBanner.alpha = 0;
    [self.view addSubview:self.adBanner];
    
    //set up spinner so it doesn't look as ugly
    UIView *newSpinnerView = [[UIView alloc] initWithFrame:adBanner.frame];
    [self.view addSubview:newSpinnerView];
    newSpinnerView.backgroundColor = [UIColor whiteColor];
    self.adBannerSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIActivityIndicatorView *spinner = self.adBannerSpinner;
    float indicatorSize = self.adBannerSpinner.frame.size.width;
    spinner.frame = CGRectMake(adBanner.frame.size.width/2 - indicatorSize/2,
                               (adBanner.frame.size.height / 2.0) - (indicatorSize/2),
                               indicatorSize,
                               indicatorSize);
    spinner.tintColor = [AppEnvironmentConstants appTheme].contrastingTextColor;
    [spinner startAnimating];
    [newSpinnerView addSubview:spinner];
}

- (void)appThemePossiblyChanged
{
    [self forceTabBarToRedrawFromScratch];
}

- (void)forceTabBarToRedrawFromScratch
{
    [[UITabBar appearance] setTintColor:[AppEnvironmentConstants appTheme].contrastingTextColor];
    
    [self.centerButton removeFromSuperview];
    [self.tabBar removeFromSuperview];
    [self.tabBarView removeFromSuperview];
    
    UITabBarItem *currentTabBarItem = self.tabBar.selectedItem;
    NSUInteger currentTabBarItemIndex = [self.tabBarItems indexOfObjectIdenticalTo:currentTabBarItem];
    self.tabBarView = [[UIView alloc] init];
    self.tabBar = [[UITabBar alloc] init];
    self.tabBar.delegate = self;
    
    self.centerButtonImg = [MZCommons centerButtonImage];
    self.centerButton = [[SSBouncyButton alloc] initAsImage];
    [self.centerButton setImage:self.centerButtonImg forState:UIControlStateNormal];
    [self.centerButton setHitTestEdgeInsets:UIEdgeInsetsMake(-10, -10, -10, -10)];
    [self.centerButton addTarget:self action:@selector(centerButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
        self.tabBarView.frame = [self landscapeTabBarViewFrame];
    else
        self.tabBarView.frame = [self portraitTabBarViewFrame];
    
    if([AppEnvironmentConstants isTabBarHidden]){
        self.tabBarView.frame = CGRectMake(self.tabBarView.frame.origin.x,
                                           self.tabBarView.frame.origin.y + MZTabBarHeight,
                                           self.tabBarView.frame.size.width,
                                           self.tabBarView.frame.size.height);
    }
    
    
    self.tabBar.frame = CGRectMake(0, 0, self.tabBarView.frame.size.width, self.tabBarView.frame.size.height);
    self.centerButton.frame = [self centerBtnFrameGivenTabBarViewFrame:self.tabBarView.frame
                                                          centerBtnImg:self.centerButtonImg];
    [self.tabBarView addSubview:self.tabBar];
    [self.tabBarView addSubview:self.centerButton];
    [self.tabBarView setMultipleTouchEnabled:NO];
    
    if(! [AppEnvironmentConstants isTabBarHidden]){
        lastVisibleTabBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        if(! self.tabBarView.superview)
            [self.view addSubview:self.tabBarView];
        self.tabBarView.alpha = 1;
    }
    
    [self setTabBarItems];
    //restore selected tab bar item.
    [self.tabBar setSelectedItem:self.tabBarItems[currentTabBarItemIndex]];
}

#pragma nav bar helper
- (BOOL)prefersStatusBarHidden
{
    if(alwaysKeepStatusBarInvisible)
        return YES;
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
        return YES;
    else{
        BOOL isNavBarHidden = self.currentNavController.navigationBar.frame.origin.y < 0;
        if(isNavBarHidden)
            return YES;
        else
            return NO;
    }
}

#pragma mark - VC Rotation
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self updateAdBannerForOrientation:toInterfaceOrientation];
    
    if([AppEnvironmentConstants isTabBarHidden] && !tabBarAnimationInProgress)
        return;
    
    if(tabBarAnimationInProgress){
        if(! [AppEnvironmentConstants isTabBarHidden])
            //resolves issue
            self.tabBarView.alpha = 0;  //animation is going to hide it anyway...
        
        [self setupTabBarAndTabBarViewUsingOrientation:toInterfaceOrientation];
    }
    
    [self ensureTabBarRotatesSmoothlyToInterfaceOrientation:toInterfaceOrientation];
}

- (void)ensureTabBarRotatesSmoothlyToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if(UIInterfaceOrientationIsPortrait(toInterfaceOrientation)){
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionAllowAnimatedContent
                         animations:^{
                             [self setupTabBarAndTabBarViewUsingOrientation:toInterfaceOrientation];
                         } completion:nil];
    } else{
        int originalWidth = self.tabBarView.frame.size.width;
        [self setupTabBarAndTabBarViewUsingOrientation:toInterfaceOrientation];
        [self.tabBarView setFrame:CGRectMake(self.tabBarView.frame.origin.x,
                                             self.tabBarView.frame.origin.y,
                                             originalWidth,
                                             self.tabBarView.frame.size.height)];
        
        double delayInSeconds = 0.35;
        __weak MainScreenViewController *weakSelf = self;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:0.2 animations:^{
                [weakSelf setupTabBarAndTabBarViewUsingOrientation:toInterfaceOrientation];
            }];
        });
    }
}

#pragma mark - Random Utils
- (void)everyTabWillNeedAForcedReload
{
    //mark each viewController as 'needing a data reload.'
    for(UIViewController *vc in _viewControllers) {
        [_tabsNeedingForcedDataReload setObject:@YES
                                         forKey:[NSValue valueWithNonretainedObject:vc]];
    }
}

- (void)forceUpdateVcDataSourceIfNecessary:(UINavigationController *)navVc
{
    UIViewController *vc;
    for(UIViewController *aViewController in self.viewControllers){
        if(aViewController.navigationController == navVc){
            vc = aViewController;
            break;
        }
    }
    BOOL needToUpdateVcData = [_tabsNeedingForcedDataReload[[NSValue valueWithNonretainedObject:vc]] boolValue];
    if(needToUpdateVcData) {
        if([vc conformsToProtocol:@protocol(MainScreenViewControllerDelegate)])
            [vc performSelector:@selector(reloadDataSourceBackingThisVc)
                     withObject:nil
                     afterDelay:0];
        [_tabsNeedingForcedDataReload setObject:@NO
                                         forKey:[NSValue valueWithNonretainedObject:vc]];
    }
}

/* 
 This refreshes the VC currently being displayed when the expanded player shrinks. 
 viewWillAppear is not normally called when it shrinks, so we needed some way of updating all
 the visible cells. Doing this helps avoid weird visual bugs - like multiple songs having the
 'now playing color'.
 */
- (void)expandedPlayerIsShrinking
{
    NSUInteger index = [self.navControllers indexOfObjectIdenticalTo:self.currentNavController];
    if(index != NSNotFound) {
        UIViewController *vc = self.viewControllers[index];
        BOOL withAnimation = NO;
        [vc viewWillAppear:withAnimation];
    }
}

#pragma mark - adding music to library
- (void)centerButtonTapped
{
    UIViewController *currentVc;
    for(UIViewController *aViewController in self.viewControllers){
        if(aViewController.navigationController == self.currentNavController){
            currentVc = aViewController;
            break;
        }
    }
    if([currentVc conformsToProtocol:@protocol(MainScreenViewControllerDelegate)])
        [self performSelector:@selector(performCenterBtnTappedActionUsingVC:)
                   withObject:currentVc
                   afterDelay:0.2];
}

- (void)performCenterBtnTappedActionUsingVC:(UIViewController *)aVc
{
    UIViewController *topVc = aVc.navigationController.visibleViewController;
    if(topVc == aVc){
        if([aVc respondsToSelector:@selector(tabBarAddButtonPressed)]){
            [aVc performSelector:@selector(tabBarAddButtonPressed)];
        }
    } else{
        if([topVc respondsToSelector:@selector(tabBarAddButtonPressed)]){
            [topVc performSelector:@selector(tabBarAddButtonPressed)];
        }
    }
}

- (BOOL)shouldAutorotate
{
    return !self.introOnScreen;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if(self.introOnScreen) {
        return UIInterfaceOrientationMaskPortrait;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)userDoneWithIntroAndTermsAccepted
{
    [self performSelector:@selector(showAddSongsGettingStartedTip)
               withObject:nil
               afterDelay:0.2];
}

- (void)showAddSongsGettingStartedTip
{
    CMPopTipView *tipView = [[CMPopTipView alloc] initWithMessage:@"Tap to get started."];
    tipView.delegate = self;
    tipView.backgroundColor = [AppEnvironmentConstants appTheme].mainGuiTint;
    tipView.textColor = [UIColor whiteColor];
    tipView.has3DStyle = NO;
    tipView.hasGradientBackground = NO;
    tipView.borderColor = [UIColor clearColor];
    tipView.textFont = [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:16];
    tipView.dismissAlongWithUserInteraction = YES;
    [tipView presentPointingAtView:self.centerButton inView:self.view animated:YES];
}

#pragma mark - GADBanner delegate
- (void)adViewDidReceiveAd:(GADBannerView *)bannerView
{
    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         removeAdsShamelessPlug.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [removeAdsShamelessPlug removeFromSuperview];
                         removeAdsShamelessPlug = nil;
                     }];
    UIView *spinnerView = self.adBannerSpinner.superview;
    [self.adBannerSpinner stopAnimating];
    [self.adBannerSpinner removeFromSuperview];
    [UIView animateWithDuration:0.5 animations:^{
        self.adBanner.alpha = 1;
        [spinnerView removeFromSuperview];
    }];
}

static UILabel *removeAdsShamelessPlug = nil;
- (void)adView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(GADRequestError *)error
{
    UIView *spinnerView = self.adBannerSpinner.superview;
    [self.adBannerSpinner stopAnimating];
    [self.adBannerSpinner removeFromSuperview];
    [UIView animateWithDuration:0.5 animations:^{
        [spinnerView removeFromSuperview];
    }];
    
    int bannerHeight = bannerView.frame.size.height;
    CGRect currFrame = self.tabBarView.frame;
    CGRect newFrame = CGRectMake(0, currFrame.origin.y + currFrame.size.height, currFrame.size.width, bannerHeight);
    if(removeAdsShamelessPlug == nil) {
        removeAdsShamelessPlug = [[UILabel alloc] initWithFrame:newFrame];
        removeAdsShamelessPlug.numberOfLines = 1;
        removeAdsShamelessPlug.textColor = [AppEnvironmentConstants appTheme].contrastingTextColor;
        removeAdsShamelessPlug.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:15];
        removeAdsShamelessPlug.textAlignment = NSTextAlignmentCenter;
        removeAdsShamelessPlug.text = @"Did you know ads can be removed in settings?";
    } else {
        removeAdsShamelessPlug.frame = newFrame;
    }
    removeAdsShamelessPlug.alpha = 0;
    [self.view addSubview:removeAdsShamelessPlug];
    [UIView animateWithDuration:0.8
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         removeAdsShamelessPlug.alpha = 1;
                     }
                     completion:nil];

}

#pragma mark - CMPopTipView delegate
- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView {}

#pragma mark - Showing user tip when song played for first time
- (void)newSongIsLoading:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:MZNewSongLoading]) {
        if(! [AppEnvironmentConstants userSawExpandingPlayerTip]) {
            [self performSelector:@selector(showSwipeUpTipForExpandingPlayer)
                       withObject:nil
                       afterDelay:0.5];
        }
    }
}

static UIImageView *playerExpansionTipView = nil;
- (void)showSwipeUpTipForExpandingPlayer
{
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"swipe_up_img"]];
    imgView.center = playerView.center;
    imgView.frame = CGRectMake(imgView.frame.origin.x,
                               imgView.frame.origin.y - (playerView.frame.size.height/2),
                               imgView.frame.size.width,
                               imgView.frame.size.height);
    imgView.alpha = 0;
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    [window addSubview:imgView];
    [UIView animateWithDuration:1
                          delay:0
         usingSpringWithDamping:1
          initialSpringVelocity:0.2
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         imgView.alpha = 1;
                     }
                     completion:nil];
    playerExpansionTipView = imgView;
}

- (void)dismissPlayerExpandingTip:(NSNotification *)notif
{
    if([notif.name isEqualToString:@"shouldDismissPlayerExpandingTip"]) {
        NSNumber *userExpandedPlayer = notif.object;
        [UIView animateWithDuration:0.5
                              delay:0
             usingSpringWithDamping:1
              initialSpringVelocity:0.6
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             playerExpansionTipView.alpha = 0;
                         }
                         completion:^(BOOL finished) {
                             if([userExpandedPlayer boolValue]) {
                                 [AppEnvironmentConstants setUserSawExpandingPlayerTip:YES];
                             }
                             [playerExpansionTipView removeFromSuperview];
                             playerExpansionTipView = nil;
                         }];
    }
}

@end
