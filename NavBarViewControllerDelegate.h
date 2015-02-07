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

- (void)performActionForBarButtonItem:(UIBarButtonItem *)button;

@end
