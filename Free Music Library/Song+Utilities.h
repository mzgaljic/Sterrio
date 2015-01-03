//
//  Song+Utilities.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/16/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Song.h"
#import "Artist.h"
#import "Album.h"
#import "Album+Utilities.h"
#import "Artist.h"
#import "Artist+Utilities.h"
#import "GenreConstants.h"
#import "NSObject+ObjectUUID.h"
#import "NSString+smartSort.h"

@interface Song (Utilities)

/**
 @Description Creates a new song given the arguments provided. All are optional except songName and genreCode.
*note: The GenreConstants class contains a convenience method to obtain a 'no genre code selected' int value. Use 
 this if required. Genre constant will be set to 'no genre code selected' if the provided genre code is invalid.
@param  songName   name for the created song; required field.
@param  albumOrAlbumName    an Album object (if the created song should be a part of that album), or an NSString
                            object (with the albums name) if an album should be created for this song. nil if not desired.
@param  artistOrArtistName  an Artist object (if the created song should be a part of that artist), or an NSString
                            object (with the artists name) if an artist should be created for this song. nil if not desired.
@param  genreCode           The genre code to be given to this song after it is created. If genreCode is an invalid genre
                            code, the 'no genre code selected' code will be applied by default; required field.
@param  context             An NSManagedObjectContext object, which is requied for the backing core data store. If this
                            parameter is nil, nil shall be returned. Optional (but crucial) argument.*/
+ (Song *)createNewSongWithName:(NSString *)songName
           inNewOrExistingAlbum:(id)albumOrAlbumName
          byNewOrExistingArtist:(id)artistOrArtistName
                        inGenre:(int)genreCode
               inManagedContext:(NSManagedObjectContext *)context;

/**
 @Description Returns YES if (and only if) both songs in the array are considered to be 'equal', or the 'same'. All
                other cases result in NO being returned. Comaprison is accomplished via the objects song id's.
 @param arrayOfTwoSongObjects   Comparisons will only take place if the argument conatins exactly two Song objects.
 */
+ (BOOL)areSongsEqual:(NSArray *)arrayOfTwoSongObjects;

- (BOOL)setAlbumArt:(UIImage *)image;
- (void)removeAlbumArt;

@end