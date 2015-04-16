//
//  PlayableBaseDataSource.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/26/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "StackController.h"
#import "UIImage+colorImages.h"
#import <FXImageView/UIImage+FX.h>
#import "PlaybackContext.h"
#import "MZTableViewCell.h"
#import "SongTableViewFormatter.h"
#import "PreferredFontSizeUtility.h"
#import "MSCellAccessory.h"
#import "UIColor+LighterAndDarker.h"
#import "AlbumArtUtilities.h"
#import "MZCoreDataModelDeletionService.h"
#import "MusicPlaybackController.h"
#import "MGSwipeButton.h"
#import "MySearchBar.h"
#import "NSString+WhiteSpace_Utility.h"
#import "SearchBarDataSourceDelegate.h"
#import "KnownEnums.h"


@interface PlayableBaseDataSource : NSObject
@property (nonatomic, assign) id <SearchBarDataSourceDelegate> searchBarDataSourceDelegate;
@property (nonatomic, strong) NSString *emptyTableUserMessage;
- (UIColor *)colorForNowPlayingItem;
- (MySearchBar *)setUpSearchBar;

#pragma mark - Boring utility methods for subclasses
- (UIViewController *)topViewController;
- (UIViewController *)topViewController:(UIViewController *)rootViewController;
@end

/*
@protocol DataSourceEmptyCallbackDelegate <NSObject>

//Classes may implement this method if they wish to be
//notified anytime the interface is
//- (void)shouldDisplayEmptyDataSource:(BOOL)empty;

@end
*/