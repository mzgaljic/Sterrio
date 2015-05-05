//
//  AllAlbumsDataSource.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/16/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "PlayableBaseDataSource.h"
#import "ActionableAlbumDataSourceDelegate.h"

//for playlists  (not used yet)
//#define ADD_String @"Add"
//#define AddLater_String @"Add later"
//#define Cancel_String @"Cancel"

@class StackController;
@interface AllAlbumsDataSource : PlayableBaseDataSource <UITableViewDataSource,
                                                        UITableViewDelegate,
                                                        MGSwipeTableCellDelegate,
                                                        PlayableDataSearchDataSourceDelegate,
                                                        SearchBarDataSourceDelegate>
{
    StackController *stackController;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) PlaybackContext *playbackContext;
@property (nonatomic, strong) NSString *cellReuseId;
@property (nonatomic, assign) id <ActionableAlbumDataSourceDelegate> actionableAlbumDelegate;
//@property (nonatomic, assign) id <PlaylistSongAdderDataSourceDelegate> playlistSongAdderDelegate;

//- (NSArray *)minimallyFaultedArrayOfSelectedPlaylistSongs;


- (instancetype)initWithAlbumDataSourceType:(ALBUM_DATA_SRC_TYPE)type
                searchBarDataSourceDelegate:(id<SearchBarDataSourceDelegate>)delegate;

- (instancetype)initWithAlbumDataSourceType:(ALBUM_DATA_SRC_TYPE)type
                              selectedAlbum:(Album *)anAlbum
                searchBarDataSourceDelegate:(id<SearchBarDataSourceDelegate>)delegate;

//exposed so that the Album VC can check if any visible Album cells contain "dirty" album art.
- (Album *)albumAtIndexPath:(NSIndexPath *)indexPath;

@end
