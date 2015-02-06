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


@interface MainScreenViewController()

//controls which view controller is displayed at any given moment.
@property (nonatomic, strong) HMSegmentedControl *segmentedVcControl;

//Array of SegmentedControl items to switch between (contains VC pointers)
@property (nonatomic, strong) NSArray *allSegmentedControlItems;

//Currently selected view controller
@property(nonatomic, assign) NSUInteger currentVCIndex;
@end


@implementation MainScreenViewController

#pragma mark - ViewController Lifecycle
- (instancetype)initWithSegmentedControlItems:(NSArray *)segmentedControlItems
{
    NSDictionary *options = [[NSMutableDictionary alloc] initWithCapacity:1];
    CGFloat spacingVal = 4;
    NSNumber *spacing = [NSNumber numberWithFloat:spacingVal];
    [options setValue:spacing forKey:UIPageViewControllerOptionInterPageSpacingKey];

    if([super initWithTransitionStyle:transitionStyle navigationOrientation:navigationOrientation options:options]){
        _allSegmentedControlItems = segmentedControlItems;
        [self setupViewControllerIndexesAndTags];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    self.currentVCIndex = 0;
    self.dataSource = self;
    self.delegate = self;
    
    //can only add 1 VC on initialization!
    [self setViewControllers:@[[self allViewControllers][self.currentVCIndex]]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSMutableArray *sectionTitles;
    sectionTitles = [[NSMutableArray alloc] initWithCapacity:self.allSegmentedControlItems.count];
    for(SegmentedControlItem *item in self.allSegmentedControlItems){
        [sectionTitles addObject:item.itemName];
    }
    
    self.segmentedVcControl = [[HMSegmentedControl alloc] initWithSectionTitles:sectionTitles];
    self.segmentedVcControl.frame = CGRectMake(0, 70, self.view.frame.size.width, 60);
    self.segmentedVcControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
    self.segmentedVcControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
    [self.segmentedVcControl addTarget:self
                                action:@selector(indexDidChangeForCustomSegmentedControl:)
                      forControlEvents:UIControlEventValueChanged];
    [self.shyNavBarManager setExtensionView:self.segmentedVcControl];
    
    //taking advantage of TLYShyBar library capabilities if possible...
    UIViewController *onScreenVc = [self allViewControllers][self.currentVCIndex];
    if ([onScreenVc respondsToSelector:@selector(tableView)]) {
        UITableView *vcTableView = [onScreenVc performSelector:@selector(tableView)];
        self.shyNavBarManager.scrollView = vcTableView;
    }else if ([onScreenVc respondsToSelector:@selector(scrollView)]) {
        UIScrollView *vcScrollView = [onScreenVc performSelector:@selector(scrollView)];
        self.shyNavBarManager.scrollView = vcScrollView;
    }
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
    currentController = [self.viewControllers objectAtIndex:0];
    self.currentVCIndex = currentController.view.tag;
    [self.segmentedVcControl setSelectedSegmentIndex:self.currentVCIndex animated:YES];
}

#pragma mark - Page Controller added functions
- (void)animatePageViewControllerScrollToIndex:(NSUInteger)index
{
    if(self.currentVCIndex == index)
        return;
    BOOL forward = (self.currentVCIndex < index);
    self.currentVCIndex = index;
    NSInteger animateDirection;
    if(forward)
        animateDirection = UIPageViewControllerNavigationDirectionForward;
    else
        animateDirection =UIPageViewControllerNavigationDirectionReverse;
    [self setViewControllers:@[[self allViewControllers][index]]
                                      direction:animateDirection
                                       animated:YES
                                     completion:nil];
}

- (void)indexDidChangeForCustomSegmentedControl:(UISegmentedControl *)sender
{
    [self animatePageViewControllerScrollToIndex:[sender selectedSegmentIndex]];
}

#pragma mark - Convenience Utility methods
- (void)setupViewControllerIndexesAndTags
{
    SegmentedControlItem *item;
    for(int i = 0; i < self.allSegmentedControlItems.count; i++){
        item = self.allSegmentedControlItems[i];
        item.indexAndTag = i;
        item.viewController.view.tag = i;
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

@end
