//
//  Artist.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Artist.h"
#import "FileIOConstants.h"
#define ARTIST_NAME_KEY @"artistName"

@implementation Artist
@synthesize artistName;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        self.artistName = [aDecoder decodeObjectForKey:ARTIST_NAME_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.artistName forKey:ARTIST_NAME_KEY];
}

+ (NSArray *)loadAll  //loads array containing all of the saved artists
{
    NSData *data = [NSData dataWithContentsOfURL:[FileIOConstants createSingleton].libraryFileURL];
    if(!data){
        //if no artists exist yet (file not yet written to disk), return empty array
        return [NSMutableArray array];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];  //decode loaded data
}

- (BOOL)save  //saves the current artist (instance of this class) to the list of all artists on disk
{
    NSMutableArray *artists = (NSMutableArray *)[Artist loadAll];
    
    //should sort this array based on alphabetical order!
    [artists insertObject:self atIndex:0];  //new artists added to array will appear at top of 'list'
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:artists];  //encode artists
    return [fileData writeToURL:[FileIOConstants createSingleton].libraryFileURL atomically:YES];
}

- (BOOL)deleteAlbum
{
    return NO;
}

- (NSMutableArray *)sortExistingArrayAlphabetically:(NSMutableArray *)unsortedArray
{
    return nil;
}

- (NSMutableArray *)insertNewArtistIntoAlphabeticalArray:(Artist *)unInsertedArtist
{
    return nil;
}


@end
