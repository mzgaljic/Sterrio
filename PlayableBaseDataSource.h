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
#import "NowPlayingSong.h"
#import "AlbumArtUtilities.h"
#import "MusicPlaybackController.h"
#import "MGSwipeButton.h"
#import "MySearchBar.h"
#import "NSString+WhiteSpace_Utility.h"


typedef enum{
    SONG_DATA_SRC_TYPE_Default,
    SONG_DATA_SRC_TYPE_Playlist_MultiSelect
} SONG_DATA_SRC_TYPE;

typedef enum{
    PLAYLIST_STATUS_In_Creation,
    PLAYLIST_STATUS_Created_But_Empty,
    PLAYLIST_STATUS_Normal_Playlist
} PLAYLIST_STATUS;

@protocol PlaylistSongAdderDataSourceDelegate <NSObject>
- (void)setSuccessNavBarButtonStringValue:(NSString *)newValue;
- (PLAYLIST_STATUS)currentPlaylistStatus;
- (NSOrderedSet *)existingPlaylistSongs;
@end

@protocol SearchBarDataSourceDelegate <NSObject>
- (void)searchBarIsBecomingActive;
- (void)searchBarIsBecomingInactive;
@end


@interface PlayableBaseDataSource : NSObject
@property (nonatomic, assign) id <SearchBarDataSourceDelegate> searchBarDataSourceDelegate;
@property (nonatomic, strong) NSString *emptyTableUserMessage;
- (UIColor *)colorForNowPlayingItem;
- (MySearchBar *)setUpSearchBar;
@end

/*
@protocol DataSourceEmptyCallbackDelegate <NSObject>

//Classes may implement this method if they wish to be
//notified anytime the interface is
//- (void)shouldDisplayEmptyDataSource:(BOOL)empty;

@end
*/