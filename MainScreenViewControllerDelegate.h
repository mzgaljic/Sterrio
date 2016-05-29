//
//  MainScreenViewControllerDelegate.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/6/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//used by the four viewcontrollers in the tab bar (used by its nav AND view controllers)
@protocol MainScreenViewControllerDelegate <NSObject>

- (NSArray *)leftBarButtonItemsForNavigationBar;
- (NSArray *)rightBarButtonItemsForNavigationBar;
- (void)tabBarAddButtonPressed;
- (void)reloadDataSourceBackingThisVc;

@end
