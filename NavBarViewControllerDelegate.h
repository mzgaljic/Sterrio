//
//  MainScreenNavBarViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/6/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol NavBarViewControllerDelegate <NSObject>

- (NSArray *)leftBarButtonItemsForNavigationBar;
- (NSArray *)rightBarButtonItemsForNavigationBar;
- (NSString *)titleOfNavigationBar;

@optional

/**
 When a VC will be iterated over but is NOT the final destination on the
 UIPageViewController, this method will be called on the delegates as needed.
 This helps those VC's avoid updating the GUI for no reason...if that specific
 VC decides that it can display slightly outdated information on the interface.
 */
- (void)viewControllerWillBeIteratedPastInSegmentControl;

- (void)navigationControllerNavBarForOptionalCustomization:(UINavigationBar *)navBar;

@end
