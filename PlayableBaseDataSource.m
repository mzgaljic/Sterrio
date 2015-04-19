//
//  PlayableBaseDataSource.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/26/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "PlayableBaseDataSource.h"
#import "StackController.h"
#import "PlaybackContext.h"
#import "MZTableViewCell.h"
#import "PreferredFontSizeUtility.h"

#import "AlbumArtUtilities.h"
#import "MZCoreDataModelDeletionService.h"
#import "MusicPlaybackController.h"

#import "NSString+WhiteSpace_Utility.h"

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

//override for real functionality in subclasses.
- (NSIndexPath *)indexPathInSearchTableForObject:(id)someObject
{
    return nil;
}

#pragma mark - Boring utility methods for subclasses
- (UIViewController *)topViewController
{
    return [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

//from snikch on Github
- (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil)
        return rootViewController;
    
    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}


@end
