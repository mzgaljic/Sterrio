//
//  UpNextSongQueue.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/27/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "UpNextSongQueue.h"

@implementation UpNextSongQueue
//Deque class performs all required nil/null checks. If thread safe code is to be added to the model, add it here, not in deque.
static Deque *songQueue;


+ (void)addSongToUpNext:(Song *)aSong;
{
    [songQueue enqueue:aSong];
}

+ (void)addSongsToUpNext:(NSArray *)unAddedSongsArray
{
    [songQueue enqueueObjectsFromArray:unAddedSongsArray];
}

+ (void)addAlbumToUpNext:(Album *)unAddedAlbumArray
{
    [songQueue enqueueObjectsFromArray:unAddedAlbumArray.albumSongs];
}

+ (void)addPlaylistToUpNext:(Playlist *)aPlaylist
{
    [songQueue enqueueObjectsFromArray:aPlaylist.songsInThisPlaylist];
}

+ (void)addAllSongsFromTheArtist:(Artist *)anArtist
{
    NSArray *songs = [Song loadAll];
    NSString *targetArtistName = anArtist.artistName;
    
    //iterate through all songs in library and find out which artists match the target
    for(Song *someSong in songs){
        if([someSong.artist.artistName isEqualToString:targetArtistName])
            [songQueue enqueue:someSong];
    }
}

+ (Song *)nextSong
{
    return [songQueue peekAtHead];
}

+ (NSArray *)listOfUpNextSongs
{
    return [songQueue allQueueObjectsAsArray];
}

+ (void)changeOrderOfUpNextTo:(NSArray *)reorderedSongs
{
    [songQueue newOrderOfQueue:reorderedSongs];
}

@end
