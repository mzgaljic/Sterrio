//
//  AllPlaylistsDataSource.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/22/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "PlayableBaseDataSource.h"
#import "ActionablePlaylistDataSourceDelegate.h"

@class StackController;
@interface AllPlaylistsDataSource : PlayableBaseDataSource
                                        <UITableViewDataSource,
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
@property (nonatomic, assign) id <ActionablePlaylistDataSourceDelegate> actionablePlaylistDelegate;

- (instancetype)initWithPlaylisttDataSourceType:(PLAYLIST_DATA_SRC_TYPE)type
                 searchBarDataSourceDelegate:(id<SearchBarDataSourceDelegate>)delegate;
@end
