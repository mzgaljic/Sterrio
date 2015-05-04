//
//  PlaylistItem+Utilities.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/4/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "PlaylistItem+Utilities.h"
#import "NSObject+ObjectUUID.h"

@implementation PlaylistItem (Utilities)

+ (PlaylistItem *)createNewPlaylistItemWithCorrespondingPlaylist:(Playlist *)aPlaylist
                                                            song:(Song *)aSong
                                                 indexInPlaylist:(short)index
                                                inManagedContext:(NSManagedObjectContext *)context
{
    /*
     
     if(context == nil || name == nil)
     return nil;
     
     Playlist *newPlaylist = [NSEntityDescription insertNewObjectForEntityForName:@"Playlist" inManagedObjectContext:context];
     newPlaylist.uniqueId = [[NSObject UUID] copy];
     newPlaylist.playlistName = name;
     newPlaylist.creationDate = [NSDate date];
     
     return newPlaylist;
     */
    if(context == nil || aPlaylist == nil || aSong == nil)
        return nil;
    
    PlaylistItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"PlaylistItem"
                                                          inManagedObjectContext:context];
    newItem.uniqueId = [[NSObject UUID] copy];
    newItem.song = aSong;
    newItem.index = [NSNumber numberWithShort:index];
    
    return newItem;
}

@end
