//
//  UIButton+ExpandedHitArea.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/12/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
//This category gets the job done, but it is generally NOT recommended to override a methods behavior in a category.

@interface UIButton (ExpandedHitArea)

@property(nonatomic, assign) UIEdgeInsets hitTestEdgeInsets;

@end
