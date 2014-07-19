//
//  Playlist.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppEnvironmentConstants.h"

@interface Playlist : NSObject <NSCoding>

@property (nonatomic, strong) NSString *playlistName;
@property (nonatomic, strong) NSMutableArray *songsInThisPlaylist;
@property (atomic, assign) short status;  //used in song picker

+ (NSArray *)loadAll;
///should be saved upon Playlists creation
- (BOOL)savePlaylist;
- (BOOL)deletePlaylist;
- (BOOL)updateExistingPlaylist;

//used when adding songs to playlists and creating them (passing playlist object via disk)
- (BOOL)saveTempPlaylistOnDisk;
+ (Playlist *)loadTempPlaylistFromDisk;
+ (BOOL)reInsertTempPlaylist:(Playlist *)playlistToInsert;

@end
