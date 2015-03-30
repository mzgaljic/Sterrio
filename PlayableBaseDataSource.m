//
//  PlayableBaseDataSource.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/26/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "PlayableBaseDataSource.h"

@implementation PlayableBaseDataSource

- (UIColor *)colorForNowPlayingItem
{
    return [[UIColor defaultAppColorScheme] lighterColor];
}

//override for actual functionality.
- (MySearchBar *)setUpSearchBar
{
    return nil;
}

@end
