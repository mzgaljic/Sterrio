//
//  MainScreenViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MainScreenViewController.h"

//page view controller constants
const short transitionStyle = UIPageViewControllerTransitionStyleScroll;
const short navigationOrientation = UIPageViewControllerNavigationOrientationHorizontal;
const short segmentedControlHeight = 50;


@interface MainScreenViewController()

@property (nonatomic, strong) UIPageViewController *pageViewController;

//controls which view controller is displayed at any given moment.
@property (nonatomic, strong) HMSegmentedControl *segmentedVcControl;

//Used in this case to contain an instance of HMSegmentedControl.
@property (nonatomic, strong) UIView *stickyHeaderView;

//Array of SegmentedControl items to switch between (contains VC pointers)
@property (nonatomic, strong) NSArray *allSegmentedControlItems;

//Currently selected view controller
@property(nonatomic, assign) NSUInteger currentVCIndex;

@end


@implementation MainScreenViewController

#pragma mark - ViewController Lifecycle
- (instancetype)initWithSegmentedControlItems:(NSArray *)segmentedControlItems
{
    if([super init]){
        _allSegmentedControlItems = segmentedControlItems;
        [self setupViewControllerIndexesAndTags];
        
        NSDictionary *options = [[NSMutableDictionary alloc] initWithCapacity:1];
        CGFloat spacingVal = 4;
        NSNumber *spacing = [NSNumber numberWithFloat:spacingVal];
        [options setValue:spacing forKey:UIPageViewControllerOptionInterPageSpacingKey];
        _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:transitionStyle
                                                              navigationOrientation:navigationOrientation
                                                                            options:options];
        self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.currentVCIndex = 0;
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    
    //can only add 1 VC on initialization!
    [self.pageViewController setViewControllers:@[[self allViewControllers][self.currentVCIndex]]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];
    
    int navBarHeight = self.navigationController.navigationBar.frame.size.height;
    int heightFromTopOfScreen = navBarHeight + segmentedControlHeight;
    
    //containing the UIPageViewController within a container
    CGRect pageVcFrame = CGRectMake(0,
                                    heightFromTopOfScreen,
                                    self.view.frame.size.width,
                                    self.view.frame.size.height);
    [self addChildViewController:self.pageViewController];
    self.pageViewController.view.frame = pageVcFrame;
    [self.view addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self hideNavBarOnScrollIfPossible];
    [self setupNavBarForCurrentVc];
    [self setupSegmentedControl];
}

#pragma mark - Page Controller Data Source
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSInteger prevIndex = 0;
    for(int i = 0; i < self.allViewControllers.count; i++){
        if(self.allViewControllers[i] == viewController){
            prevIndex = i -1;
            break;
        }
    }
    if(prevIndex <= self.allViewControllers.count -1 && prevIndex >= 0)
        return self.allViewControllers[prevIndex];
    else
        return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController
{
    NSInteger nextIndex = 0;
    for(int i = 0; i < self.allViewControllers.count; i++){
        if(self.allViewControllers[i] == viewController){
            nextIndex = i +1;
            break;
        }
    }
    if(nextIndex <= self.allViewControllers.count -1 && nextIndex >= 0)
        return self.allViewControllers[nextIndex];
    else
        return nil;
}

#pragma mark - Page Controller Delegate
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if(! completed)
        return;
    UIViewController *currentController;
    currentController = [self.pageViewController.viewControllers objectAtIndex:0];
    self.currentVCIndex = currentController.view.tag;
    [self.segmentedVcControl setSelectedSegmentIndex:self.currentVCIndex animated:YES];
}

#pragma mark - Page Controller added functions
- (void)animatePageViewControllerScrollToIndex:(NSUInteger)index
{
    if(self.currentVCIndex == index)
        return;
    
    int numVcsToPageThrough = abs((int)self.currentVCIndex - (int)index);
    NSInteger animateDirection;
    int forward = UIPageViewControllerNavigationDirectionForward;
    int backward = UIPageViewControllerNavigationDirectionReverse;
    BOOL animateForwards;
    animateDirection = (animateForwards = self.currentVCIndex < index) ? forward : backward;

    int iteratorIndex = (int)self.currentVCIndex;
    UIViewController *currentIndexVc;
    while(numVcsToPageThrough){
        if(animateForwards)
            currentIndexVc = [self allViewControllers][++iteratorIndex];
        else
            currentIndexVc = [self allViewControllers][--iteratorIndex];
        
        [self.pageViewController setViewControllers:@[currentIndexVc]
                                          direction:animateDirection
                                           animated:YES
                                         completion:nil];
        numVcsToPageThrough--;
    }
    
    self.currentVCIndex = index;
    [self setupNavBarForCurrentVc];
}

#pragma mark - Segmented Control targets
- (void)indexDidChangeForCustomSegmentedControl:(UISegmentedControl *)sender
{
    [self animatePageViewControllerScrollToIndex:[sender selectedSegmentIndex]];
}

#pragma mark - Convenience Utility methods
- (void)setupViewControllerIndexesAndTags
{
    SegmentedControlItem *item;
    UIViewController *someVc;
    for(int i = 0; i < self.allSegmentedControlItems.count; i++){
        item = self.allSegmentedControlItems[i];
        item.indexAndTag = i;
        someVc = (UIViewController *)item.viewController;
        someVc.view.tag = i;
    }
}

- (NSArray *)allViewControllers
{
    NSMutableArray *allViewControllers;
    allViewControllers = [[NSMutableArray alloc] initWithCapacity:self.allSegmentedControlItems.count];
    for(SegmentedControlItem *item in self.allSegmentedControlItems){
        [allViewControllers addObject:item.viewController];
    }
    return allViewControllers;
}

- (HMSegmentedControl *)createNewSegmentedControlWithFrame:(CGRect)frame
{
    NSMutableArray *sectionTitles;
    sectionTitles = [[NSMutableArray alloc] initWithCapacity:self.allSegmentedControlItems.count];
    for(SegmentedControlItem *item in self.allSegmentedControlItems){
        [sectionTitles addObject:item.itemName];
    }
    
    if(self.segmentedVcControl != nil){
        [self.segmentedVcControl removeFromSuperview];
        self.segmentedVcControl = [[HMSegmentedControl alloc] initWithSectionTitles:sectionTitles];
        self.segmentedVcControl.type = HMSegmentedControlTypeText;
        self.segmentedVcControl.frame = frame;
        self.segmentedVcControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
        short indicatorBelow = HMSegmentedControlSelectionIndicatorLocationDown;
        //self.segmentedVcControl.selectionIndicatorColor
        self.segmentedVcControl.selectionIndicatorLocation = indicatorBelow;
        [self.segmentedVcControl addTarget:self
                                    action:@selector(indexDidChangeForCustomSegmentedControl:)
                          forControlEvents:UIControlEventValueChanged];
        self.stickyHeaderView.frame = frame;
        [self.stickyHeaderView addSubview:self.segmentedVcControl];

    } else{
        self.segmentedVcControl = [[HMSegmentedControl alloc] initWithSectionTitles:sectionTitles];
        self.segmentedVcControl.type = HMSegmentedControlTypeText;
        self.segmentedVcControl.frame = frame;
        self.segmentedVcControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
        short indicatorBelow = HMSegmentedControlSelectionIndicatorLocationDown;
        //self.segmentedVcControl.selectionIndicatorColor
        self.segmentedVcControl.selectionIndicatorLocation = indicatorBelow;
        [self.segmentedVcControl addTarget:self
                                    action:@selector(indexDidChangeForCustomSegmentedControl:)
                          forControlEvents:UIControlEventValueChanged];
        self.stickyHeaderView = [[UIView alloc] initWithFrame:frame];
        [self.view addSubview:self.stickyHeaderView];
        [self.stickyHeaderView addSubview:self.segmentedVcControl];
    }
    [self.segmentedVcControl setSelectedSegmentIndex:self.currentVCIndex animated:NO];
    return self.segmentedVcControl;
}

#pragma mark - GUI helpers
- (void)setupNavBarForCurrentVc
{
    //MainScreenNavBarDelegate
    id<NavBarViewControllerDelegate> currentVC = [self allViewControllers][self.currentVCIndex];
    NSArray *leftBarButtonItems = [currentVC leftBarButtonItemsForNavigationBar];
    NSArray *rightBarButtonItems = [currentVC rightBarButtonItemsForNavigationBar];
    NSString *navBarTitle = [currentVC titleOfNavigationBar];
    
    self.navigationItem.leftBarButtonItems = leftBarButtonItems;
    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    self.navigationItem.title = navBarTitle;
}

- (void)setupSegmentedControl
{
    [self createNewSegmentedControlWithFrame:CGRectMake(0,
                                                        0,
                                                        self.view.frame.size.width,
                                                        segmentedControlHeight)];
}

- (void)hideNavBarOnScrollIfPossible
{
    /*
    NSOperatingSystemVersion ios8_0_1 = (NSOperatingSystemVersion){8, 0, 0};
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:ios8_0_1]) {
        // iOS 8 and above
        self.pageViewController.navigationController.hidesBarsOnSwipe = YES;
        self.pageViewController.navigationController.hidesBarsOnTap = NO;
    }
    */
}

#pragma mark - VC Rotation
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    float widthOfScreenRoationIndependant;
    float heightOfScreenRotationIndependant;
    float  a = [[UIScreen mainScreen] bounds].size.height;
    float b = [[UIScreen mainScreen] bounds].size.width;
    if(a < b)
    {
        heightOfScreenRotationIndependant = b;
        widthOfScreenRoationIndependant = a;
    }
    else
    {
        widthOfScreenRoationIndependant = b;
        heightOfScreenRotationIndependant = a;
    }
    
    if(toInterfaceOrientation == UIInterfaceOrientationLandscapeRight ||
       toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft){
        //landscape
        [self createNewSegmentedControlWithFrame:CGRectMake(0,
                                                            0,
                                                            heightOfScreenRotationIndependant,
                                                            segmentedControlHeight)];
    } else{
        //portrait
        [self createNewSegmentedControlWithFrame:CGRectMake(0,
                                                            0,
                                                            widthOfScreenRoationIndependant,
                                                            segmentedControlHeight)];
    }
}

@end
