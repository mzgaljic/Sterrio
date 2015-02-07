//
//  SegmentedControlItem.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "SegmentedControlItem.h"

@implementation SegmentedControlItem

- (instancetype)initWithViewController:(id<NavBarViewControllerDelegate>)vc itemName:(NSString *)name
{
    if([super init]){
        _itemName = name;
        _viewController = vc;
    }
    return self;
}

@end
