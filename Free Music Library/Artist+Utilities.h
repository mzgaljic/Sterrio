//
//  Artist+Utilities.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/16/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Artist.h"
#import "Song.h"
#import "Album.h"
#import "CoreDataManager.h"
#import "NSObject+ObjectUUID.h"
#import "NSString+smartSort.h"
#import "AppEnvironmentConstants.h"

@interface Artist (Utilities)

/**
 @Description Creates a new artist given the arguments provided. All arguments required except for context.
 @param  name                name for the created artist.
 @param  context             An NSManagedObjectContext object, which is requied for the backing core data store. If this  
                             parameter is nil, nil shall be returned.*/
+ (Artist *)createNewArtistWithName:(NSString *)name
                 inManagedContext:(NSManagedObjectContext *)context;


//use when an artist was created with the song and album
+ (Artist *)createNewArtistWithName:(NSString *)name
                          usingAlbum:(Album *)anAlbum
                   inManagedContext:(NSManagedObjectContext *)context;

/**
 @Description Returns YES if (and only if) both artists in the array are considered to be 'equal', or the 'same'. All
                other cases result in NO being returned. Comaprison is accomplished via the objects artist id.
 @param arrayOfTwoArtistObjects   Comparisons will only take place if the argument conatins exactly two Artist objects.
 */
+ (BOOL)areArtistsEqual:(NSArray *)arrayOfTwoArtistObjects;


@end
