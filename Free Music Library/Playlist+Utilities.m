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
                       inManagedContext:(NSManagedObjectContext *)context
{
    if(context == nil || name == nil)
        return nil;
    
    Playlist *newPlaylist = [NSEntityDescription insertNewObjectForEntityForName:@"Playlist" inManagedObjectContext:context];
    newPlaylist.uniqueId = [[NSObject UUID] copy];
    newPlaylist.playlistName = name;
    newPlaylist.creationDate = [NSDate date];
    
    return newPlaylist;
}

+ (BOOL)arePlaylistsEqual:(NSArray *)arrayOfTwoPlaylistObjects
{
    if(arrayOfTwoPlaylistObjects.count == 2){
        if([[arrayOfTwoPlaylistObjects[0] uniqueId] isEqualToString:[arrayOfTwoPlaylistObjects[1] uniqueId]])
            return YES;
    }
    return NO;
}

+ (BOOL)isPlaylist:(Playlist *)playlist1 equalToPlaylist:(Playlist *)playlist2
{
    if(playlist1 == playlist2)
        return YES;
    if([[playlist1 uniqueId] isEqualToString:[playlist2 uniqueId]])
        return YES;
    
    return NO;
}

@end
