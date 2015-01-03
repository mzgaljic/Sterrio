//
//  Album+Utilities.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/16/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Album.h"
#import "Song.h"
#import "Song+Utilities.h"
#import "NSObject+ObjectUUID.h"
#import "AlbumArtUtilities.h"
#import "NSString+smartSort.h"

@interface Album (Utilities)

/**
 @Description Creates a new album given the arguments provided. All arguments required except for context.
 @param  name                name for the created album.
 @param  aSong               Song object which will be used to create this album (required since albums cannot
                            exist without songs)
 @param  context             An NSManagedObjectContext object, which is requied for the backing core data store. If this
                            parameter is nil, nil shall be returned.*/
+ (Album *)createNewAlbumWithName:(NSString *)name
                        usingSong:(Song *)aSong
                 inManagedContext:(NSManagedObjectContext *)context;

/**
 @Description Returns YES if (and only if) both albums in the array are considered to be 'equal', or the 'same'. All
                other cases result in NO being returned. Comaprison is accomplished via the objects album id.
 @param arrayOfTwoAlbumObjects   Comparisons will only take place if the argument conatins exactly two Album objects.
 */
+ (BOOL)areAlbumsEqual:(NSArray *)arrayOfTwoAlbumObjects;


- (BOOL)setAlbumArt:(UIImage *)image;
- (void)removeAlbumArt;

@end
