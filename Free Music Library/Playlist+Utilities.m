//
//  Playlist+Utilities.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/16/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Playlist+Utilities.h"

@implementation Playlist (Utilities)

+ (Playlist *)createNewPlaylistWithName:(NSString *)name
                             usingSongs:(NSArray *)songs
                       inManagedContext:(NSManagedObjectContext *)context
{
    if(context == nil || songs == nil)
        return nil;
    Playlist *newPlaylist = [Playlist createNewPlaylistWithName:name inManagedContext:context];
    newPlaylist.playlistSongs = [NSOrderedSet orderedSetWithArray:songs];
    return newPlaylist;
}

+ (BOOL)arePlaylistsEqual:(NSArray *)arrayOfTwoPlaylistObjects
{
    if(arrayOfTwoPlaylistObjects.count == 2){
        if([[arrayOfTwoPlaylistObjects[0] playlist_id] isEqualToString:[arrayOfTwoPlaylistObjects[1] playlist_id]])
            return YES;
    }
    return NO;
}

+ (BOOL)isPlaylist:(Playlist *)playlist1 equalToPlaylist:(Playlist *)playlist2
{
    if(playlist1 == playlist2)
        return YES;
    if([[playlist1 playlist_id] isEqualToString:[playlist2 playlist_id]])
        return YES;
    
    return NO;
}

#pragma mark - private implementation
+ (Playlist *)createNewPlaylistWithName:(NSString *)name inManagedContext:(NSManagedObjectContext *)context
{
    Playlist *playlist = [NSEntityDescription insertNewObjectForEntityForName:@"Playlist" inManagedObjectContext:context];
    playlist.playlist_id = [[NSObject UUID] copy];
    playlist.playlistName = name;
    //status is 0 by default
    return playlist;
}

@end
