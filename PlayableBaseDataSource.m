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

- (instancetype)init
{
    if(self = [super init]){
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(nowPlayingSongsHasChanged:)
                                                     name:MZNewSongLoading
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//override for functionality.
- (void)nowPlayingSongsHasChanged:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:MZNewSongLoading]){
        if([NSThread isMainThread]){
            [self reflectNowPlayingChangesInTableview:notification];
        } else{
            [self performSelectorOnMainThread:@selector(reflectNowPlayingChangesInTableview:)
                                   withObject:notification
                                waitUntilDone:NO];
        }
    }
}

//override for functionality.
- (void)reflectNowPlayingChangesInTableview:(NSNotification *)notification {}

//override for functionality.
- (void)clearSearchResultsDataSource {}

//override for functionality.
- (MySearchBar *)setUpSearchBar { return nil; }

//override for functionality.
- (NSIndexPath *)indexPathInSearchTableForObject:(id)someObject { return nil; }


- (void)searchResultsShouldBeDisplayed:(BOOL)displaySearchResults
{
    _displaySearchResults = displaySearchResults;
}

- (UIColor *)colorForNowPlayingItem
{
    return [[UIColor defaultAppColorScheme] lighterColor];
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
