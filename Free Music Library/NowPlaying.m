//
//  NowPlaying.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/20/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "NowPlaying.h"

@implementation NowPlaying

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    if([super init]){
        self.nowPlaying = nil;
        self.originatingArtist = nil;
        self.originatingPlaylist = nil;
    }
    return self;
}

//if the song was selected in the song tab, then only the song parameter is set. If
//the song was selected from an artist, album, or playlist, then the appropriate parameter
//will be non-nil.
- (void)setNewNowPlayingSong:(Song *)newSong
                  fromArtist:(Artist *)artist
                   fromAlbum:(Album *)album
                fromPlaylist:(Playlist *)playlist
{
    self.nowPlaying = newSong;
    self.originatingArtist = artist;
    self.originatingAlbum = album;
    self.originatingPlaylist = playlist;
}

- (BOOL)isEqual:(Song *)aSong
{
    if([self.nowPlaying.song_id isEqualToString:aSong.song_id]){
        //now check if the songs originate from the same source (album, playlist, etc)
        if([self.originatingArtist.artist_id isEqualToString:aSong.artist.artist_id]){
            return YES;
        }
        if([self.originatingAlbum.album_id isEqualToString:aSong.album.album_id]){
            return YES;
        }
        
        if(self.originatingPlaylist.playlist_id){
            NSSet *playlists = [aSong playlistIAmIn];
            NSArray *playlistArray = [playlists allObjects];
            for(Playlist *somePlaylist in playlistArray) {
                if([somePlaylist.playlist_id isEqualToString:self.originatingPlaylist.playlist_id])
                    return YES;
            }
        }
        //if none of the above conditions were met than it must have been from the songs tab.
        return YES;
    }
    return NO;
}

@end
