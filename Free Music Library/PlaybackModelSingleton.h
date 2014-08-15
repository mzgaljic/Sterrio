//
//  PlaybackModelSingleton.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/9/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"
#import "Playlist.h"
#import "Album.h"

@interface PlaybackModelSingleton : NSObject
@property (nonatomic, strong, readonly) Song *nowPlayingSong;
@property (nonatomic, assign, readonly) NSUInteger printFrienlyNowPlayingSongNumber;
@property (nonatomic, assign, readonly) NSUInteger printFrienlyTotalSongsInCollectionNumber;
@property (nonatomic, assign) BOOL userWantsPlaybackPaused;
@property (nonatomic, assign) BOOL lastSongHasEnded;

#pragma mark - Initialization
+ (instancetype)createSingleton;

#pragma mark - Changing the playback model

- (void)changeNowPlayingWithSong:(Song *)nextSong fromAllSongs:(NSArray *)allSongs indexOfNextSong:(NSUInteger)index;

/** Update the currently playing song to 'nextSong'. If 'newOrSamePlaylist' is not nil, any existing
 queue's will be destoryed, and a new one will be created, using information from the playlist. Triggers
 playback. */
- (void)changeNowPlayingWithSong:(Song *)nextSong fromPlaylist:(Playlist *)newPlaylist;

/** Update the currently playing song to 'nextSong'. If 'newAlbum' is not nil, any existing
 queue's will be destoryed, and a new one will be created, using information from the album. Triggers
 playback. */
- (void)changeNowPlayingWithSong:(Song *)nextSong fromAlbum:(Album *)newAlbum;


/**  Do if i have time
#pragma mark - Updating the playback model
+ (void)addSongToUpNext:(Song *)aSong;
+ (void)addSongsToUpNext:(NSArray *)aSongs;
+ (void)addAlbumSongsToUpNext:(Album *)anAlbum;
+ (void)addPlaylistSongsToUpNext:(Playlist *)aPlaylist;
+ (void)addAllSongsFromArtistToUpNext:(Artist *)anArtist;
 */

#pragma mark - Querying the model
/** Returns the list of songs which will be playing after the Now Playing song, beginning with the Now Playing Song (index 0 in array). If no queue exists, nil is returned */
- (NSArray *)listOfUpcomingSongsInQueue;
@end
