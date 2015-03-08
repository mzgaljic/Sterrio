//
//  MainScreenViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MainScreenViewController.h"

NSString * const CENTER_BTN_IMG_NAME = @"add_song_plus";
short const dummyTabIndex = 2;

@interface MainScreenViewController()
@property (nonatomic, strong) UIView *tabBarView;  //contains the tab bar and center button - the whole visual thing.
@property (nonatomic, strong) UITabBar *tabBar;  //this tab bar is containing within a tab bar view
@property (nonatomic, strong) UIButton *centerButton;
@property (nonatomic, strong) UIImage *centerButtonImg;
@property (nonatomic, strong) NSArray *navControllers;
@property (nonatomic, strong) NSArray *viewControllers;
@property (nonatomic, strong) NSArray *tabBarUnselectedImageNames;
@property (nonatomic, strong) NSArray *tabBarItems;
@property (nonatomic, strong) UINavigationController *currentNavController;
@end


@implementation MainScreenViewController

#pragma mark - ViewController Lifecycle
- (instancetype)initWithNavControllers:(NSArray *)navControllers
          correspondingViewControllers:(NSArray *)viewControllers
                    tabBarImageNames:(NSArray*)names
{
    if([super init]){
        self.navControllers = navControllers;
        self.viewControllers = viewControllers;
        self.tabBarUnselectedImageNames = names;
        [[UITabBar appearance] setTintColor:[UIColor defaultAppColorScheme]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.currentNavController = self.navControllers[0];
    self.view.backgroundColor = [UIColor clearColor];
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    int navBarHeight = self.navigationController.navigationBar.frame.size.height;
    int statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    [AppEnvironmentConstants setNavBarHeight:navBarHeight];
    [AppEnvironmentConstants setStatusBarHeight:statusBarHeight];
    
    [self replaceNavControllerOnScreenWithNavController:self.navControllers[0]];
    
    [self hideNavBarOnScrollIfPossible];
    [self setupTabBarAndTabBarView];
    if(self.tabBarItems == nil)
        [self createTabBarItems];
    
    [self setTabBarItemsAnimatedWithADelay];
}

#pragma mark - Tab bar delegates
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    int tabIndex = (int)[[tabBar items] indexOfObject:item];
    int visualTabIndex = tabIndex;
    if(tabIndex > dummyTabIndex)
        visualTabIndex--;
    NSLog(@"Visual index tapped:%i Actual tab index tapped: %i", visualTabIndex, tabIndex);
    [self replaceNavControllerOnScreenWithNavController:self.navControllers[visualTabIndex]];
}

#pragma mark - GUI helpers
- (void)replaceNavControllerOnScreenWithNavController:(UINavigationController *)newNavController
{
    //containing the nav controller within a container
    CGRect desiredVcFrame = CGRectMake(0,
                                       0,
                                       self.view.frame.size.width,
                                       self.view.frame.size.height - MZTabBarHeight);
    self.currentNavController = newNavController;
    [self addChildViewController:self.currentNavController];
    self.currentNavController.view.frame = desiredVcFrame;
    [self.view addSubview:self.currentNavController.view];
    [self.currentNavController didMoveToParentViewController:self];
}

//general setup when not rotating the screen
- (void)setupTabBarAndTabBarView
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    [self setupTabBarAndTabBarViewUsingOrientation:orientation];
}

//helper for setupTabBarAndTabBarView, and used for screen rotation
- (void)setupTabBarAndTabBarViewUsingOrientation:(UIInterfaceOrientation)orientation
{
    if(self.tabBarView == nil){
        self.tabBarView = [[UIView alloc] init];
        self.tabBar = [[UITabBar alloc] init];
        self.tabBar.delegate = self;
        self.centerButtonImg = [UIImage colorOpaquePartOfImage:[UIColor defaultAppColorScheme]
                                                              :[UIImage imageNamed:CENTER_BTN_IMG_NAME]];
        self.centerButton = [[UIButton alloc] init];
        [self.centerButton setImage:self.centerButtonImg forState:UIControlStateNormal];
        [self.centerButton setHitTestEdgeInsets:UIEdgeInsetsMake(-10, -10, -10, -10)];
        [self.centerButton addTarget:self action:@selector(addMusicToLibButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if(orientation == UIInterfaceOrientationLandscapeLeft
       || orientation == UIInterfaceOrientationLandscapeRight){
        self.tabBarView.frame = [self landscapeTabBarViewFrame];
    } else{
        self.tabBarView.frame = [self portraitTabBarViewFrame];
    }
    self.tabBar.frame = CGRectMake(0, 0, self.tabBarView.frame.size.width, self.tabBarView.frame.size.height);
    self.centerButton.frame = [self centerBtnFrameGivenTabBarViewFrame:self.tabBarView.frame
                                                          centerBtnImg:self.centerButtonImg];
    [self.tabBarView addSubview:self.tabBar];
    [self.tabBarView addSubview:self.centerButton];
    [self.tabBarView setMultipleTouchEnabled:NO];
    [self.view addSubview:self.tabBarView];
}

- (void)setTabBarItemsAnimatedWithADelay
{
    __weak UITabBarItem *selectedItem = [self.tabBar selectedItem];
    if(selectedItem == nil)  //setting default
        selectedItem = self.tabBarItems[0];
    
    [self.tabBar setItems:nil animated:NO];
    double delayInSeconds = 0.3;
    __weak MainScreenViewController *weakself = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakself.tabBar setItems:weakself.tabBarItems animated:YES];
        [weakself.tabBar setSelectedItem:selectedItem];
    });
}

- (void)createTabBarItems
{
    NSMutableArray *tabBarItems = [NSMutableArray array];
    UITabBarItem *someItem;
    UIImage *unselectedImg;
    NSString *unselectedImgFileName;
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
        if(unselectedImgFileName.length > 0)  //not needed but faster since program doesnt need to check assets.
            unselectedImg = [UIImage imageNamed:unselectedImgFileName];
        someItem = [[UITabBarItem alloc] initWithTitle:aNavController.title image:unselectedImg selectedImage:nil];
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
    int yVal = portraitHeight - MZTabBarHeight;
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
    int yVal = landscapeHeight - MZTabBarHeight;
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

#pragma nav bar helper
- (void)hideNavBarOnScrollIfPossible
{
    NSOperatingSystemVersion ios8_0_1 = (NSOperatingSystemVersion){8, 0, 0};
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:ios8_0_1]) {
        // iOS 8 and above
        self.currentNavController.hidesBarsOnSwipe = YES;
        self.currentNavController.hidesBarsOnTap = NO;
    }
}

- (BOOL)prefersStatusBarHidden
{
    BOOL hidden = self.currentNavController.navigationBarHidden;
    //nav bar coming back on screen, no issue
    if(!hidden){
        forcingStatusBarToHide = NO;
        return hidden;
    }
    else{
        if(forcingStatusBarToHide){
            forcingStatusBarToHide = NO;
            return YES;
        }
        
        //nav bar hiding, want to avoid jerking all content up!
        [self performSelector:@selector(makeStatusBarDissapear) withObject:nil afterDelay:0.0001];
        return NO;
    }
}

static BOOL forcingStatusBarToHide = NO;
- (void)makeStatusBarDissapear
{
    forcingStatusBarToHide = YES;
    [UIView animateWithDuration:0.2 animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}

#pragma mark - VC Rotation
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self setupTabBarAndTabBarViewUsingOrientation:toInterfaceOrientation];
}

#pragma mark - adding music to library
- (void)addMusicToLibButtonTapped
{
    UIViewController *currentVc;
    for(UIViewController *aViewController in self.viewControllers){
        if(aViewController.navigationController == self.currentNavController){
            currentVc = aViewController;
            break;
        }
    }
    if([currentVc conformsToProtocol:@protocol(MainScreenViewControllerDelegate)])
        [currentVc performSelector:@selector(tabBarAddButtonPressed) withObject:nil];
}

@end
