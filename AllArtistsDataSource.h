//
//  AllArtistsDataSource.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/20/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "PlayableBaseDataSource.h"
#import "ActionableArtistDataSourceDelegate.h"

@class StackController;
@interface AllArtistsDataSource : PlayableBaseDataSource <UITableViewDataSource,
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
@property (nonatomic, assign) id <ActionableArtistDataSourceDelegate> actionableArtistDelegate;


- (instancetype)initWithArtistDataSourceType:(ARTIST_DATA_SRC_TYPE)type
                searchBarDataSourceDelegate:(id<SearchBarDataSourceDelegate>)delegate;

- (instancetype)initWithArtistDataSourceType:(ARTIST_DATA_SRC_TYPE)type
                              selectedArtist:(Artist *)anArtist
                searchBarDataSourceDelegate:(id<SearchBarDataSourceDelegate>)delegate;

@end
