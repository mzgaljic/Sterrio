//
//  SegmentedControlItem.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MainScreenNavBarDelegate.h"

@interface SegmentedControlItem : NSObject

///The UIViewController associated with this item in the SegmentedControl.
@property(nonatomic, strong) UIViewController *viewController;

///Text to display for this item in the SegmentedControl.
@property(nonatomic, strong) NSString *itemName;

///This value may be set, but its effect will be nonexistant. This property is used
///within the implementation of the SegmentedControl.
@property(nonatomic, assign) NSUInteger indexAndTag;

- (instancetype)initWithViewController:(id<MainScreenNavBarDelegate>)vc itemName:(NSString *)name;

@end
