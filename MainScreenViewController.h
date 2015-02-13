//
//  MainScreenViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HMSegmentedControl/HMSegmentedControl.h>
#import "SegmentedControlItem.h"
#import "MyViewController.h"
#import "AppEnvironmentConstants.h"
#import "UIColor+LighterAndDarker.h"

@interface MainScreenViewController : MyViewController <UIPageViewControllerDataSource,
                                                        UIPageViewControllerDelegate>

/**
 Initializer which will create a custom SegmentedControl and PageViewController. This is
 possible thanks to the properties in each SegmentedControlItem object (within
 segmentedControlItems array). Each segment corresponds to one UIViewController; the 
 appropriate UIViewController is determined at run time using the UIViewController property
 available in SegmentedControlItem. If the UIViewController object provided declares a
 UITableView property (or an explicit UIScrollView property) in its header, then it can take
 advantage of TLYShyBar library capabilities and hide the navigation bar on scroll.
 
 @param segmentedControlItems - Array of SegmentedControl objects, in the desired order.
 */
- (instancetype)initWithSegmentedControlItems:(NSArray *)segmentedControlItems;

@end
