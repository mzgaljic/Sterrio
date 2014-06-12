//
//  Playlist.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Playlist.h"
#define PLAYLIST_NAME_KEY @"playlistName"
#define SONGS_IN_THIS_PLAYLIST_KEY @"songsInThisPlaylist"

@implementation Playlist
@synthesize playlistName, songsInThisPlaylist;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        self.playlistName = [aDecoder decodeObjectForKey:PLAYLIST_NAME_KEY];
        self.songsInThisPlaylist = [aDecoder decodeObjectForKey:SONGS_IN_THIS_PLAYLIST_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.playlistName forKey:PLAYLIST_NAME_KEY];
    [aCoder encodeObject:self.songsInThisPlaylist forKey:SONGS_IN_THIS_PLAYLIST_KEY];
}

@end
