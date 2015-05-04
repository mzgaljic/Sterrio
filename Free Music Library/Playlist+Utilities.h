//
//  Playlist+Utilities.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/16/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Playlist.h"
#import "NSObject+ObjectUUID.h"

@interface Playlist (Utilities)
+ (Playlist *)createNewPlaylistWithName:(NSString *)name inManagedContext:(NSManagedObjectContext *)context;


/**
 @Description Returns YES if (and only if) both playlists in the array are considered to be 'equal', or the 'same'. All
            other cases result in NO being returned. Comaprison is accomplished via the objects playlist id.
 @param arrayOfTwoPlaylistObjects   Comparisons will only take place if the argument conatins exactly two Playlist objects.
 */
+ (BOOL)arePlaylistsEqual:(NSArray *)arrayOfTwoPlaylistObjects;

//may be used in future versions, not supported in 1.0
//+ (Playlist *)createNewPlaylistWithName:(NSString *)name
//                             usingAlbums:(NSArray *)albums
//                       inManagedContext:(NSManagedObjectContext *)context;

@end
