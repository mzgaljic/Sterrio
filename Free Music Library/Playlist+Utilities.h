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
 @Description Creates a new playlsit given the arguments provided. All arguments required except for context.
 @param  name                name for the created playlist (required).
 @param  songs               Song objects which will be used to create this playlist (must be non-nil).
 @param  context             An NSManagedObjectContext object, which is requied for the backing core data store. If this
                            parameter is nil, nil shall be returned.*/
+ (Playlist *)createNewPlaylistWithName:(NSString *)name
                        usingSongs:(NSArray *)songs
                 inManagedContext:(NSManagedObjectContext *)context;

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
