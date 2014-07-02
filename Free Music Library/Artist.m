//
//  Artist.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Artist.h"
#import "Song.h"
#import "FileIOConstants.h"
#define ARTIST_NAME_KEY @"artistName"
#define ALL_ARTIST_SONGS_KEY @"allSongs"
#define ALL_ARTIST_ALBUMS_KEY @"allAlbums"

@implementation Artist
@synthesize artistName, allAlbums = _allAlbums, allSongs = _allSongs;

static  int const SAVE_ARTIST = 0;
static int const DELETE_ARTIST = 1;
static int const UPDATE_ARTIST = 2;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        self.artistName = [aDecoder decodeObjectForKey:ARTIST_NAME_KEY];
        _allSongs = [aDecoder decodeObjectForKey:ALL_ARTIST_SONGS_KEY];
        _allAlbums = [aDecoder decodeObjectForKey:ALL_ARTIST_ALBUMS_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.artistName forKey:ARTIST_NAME_KEY];
    [aCoder encodeObject:_allSongs forKey:ALL_ARTIST_SONGS_KEY];
    [aCoder encodeObject:_allAlbums forKey:ALL_ARTIST_ALBUMS_KEY];
}

+ (NSArray *)loadAll  //loads array containing all of the saved artists
{
    NSData *data = [NSData dataWithContentsOfURL:[FileIOConstants createSingleton].artistsFileURL];
    if(!data){
        //if no artists exist yet (file not yet written to disk), return empty array
        return [NSMutableArray array];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];  //decode loaded data
}

- (BOOL)saveArtist  //saves the current artist (instance of this class) to list of all artists on disk
{
    return [self performModelAction:SAVE_ARTIST];
}

- (BOOL)deleteArtist
{
    return [self performModelAction:DELETE_ARTIST];
}

- (BOOL)updateExistingArtist
{
    return [self performModelAction:UPDATE_ARTIST];
}

- (BOOL)performModelAction:(int)desiredActionConst  //does the 'hard work' of altering the model.
{
    NSMutableArray *artists = (NSMutableArray *)[Artist loadAll];
    switch (desiredActionConst) {
        case SAVE_ARTIST:
            [artists insertObject:self atIndex:0];  //new artists will appear at top of 'list'
            break;
            
        case DELETE_ARTIST:
        {
            //delete all the songs by this artist (which should erase any existing albums as well)
            NSArray *mySongs = _allSongs;
            while(mySongs.count != 0){
                [[mySongs lastObject] deleteSong];
            }
            
            //remove artist songs from any playlists?
            
            //delete the artist object itself
            [artists removeObject:self];
            break;
        }
            
        case UPDATE_ARTIST:
            //replace the old object saved in the array with the current object
            if(artists.count > 0){
                [artists replaceObjectAtIndex:[artists indexOfObject:self] withObject:self];
            }
            break;
            
        default:
            return NO;
            
    } //end of swtich
    
    //save changes to model on disk
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:artists];  //encode artists
    return [fileData writeToURL:[FileIOConstants createSingleton].artistsFileURL atomically:YES];
}

- (NSMutableArray *)sortExistingArrayAlphabetically:(NSMutableArray *)unsortedArray
{
    return nil;
}

- (NSMutableArray *)insertNewArtistIntoAlphabeticalArray:(Artist *)unInsertedArtist
{
    return nil;
}

- (BOOL)isEqual:(id)object
{
    if(self == object)  //same object instance
        return YES;
    if(!object || ![object isMemberOfClass:[self class]])  //object is nil or not an artist object
        return NO;
    
    return ([self customSmartArtistComparison:(Artist *)object]) ? YES : NO;
}

//each artist must ‘own’ a unique set of songs or albums
- (BOOL)customSmartArtistComparison:(Artist *)mysteryArtist
{
    BOOL sameName = NO, uniqueSongs = NO, uniqueAlbums = NO;
    
    if([self.artistName isEqualToString:mysteryArtist.artistName])
        sameName = YES;
    
    int numEqualSongs = 0;
    for(int i = 0; i < _allSongs.count; i++){
        if([_allSongs[i] isEqual:mysteryArtist.allSongs[i]])
            numEqualSongs++;
    }
    if(_allSongs.count == numEqualSongs)
        uniqueSongs = NO;
    else
        uniqueSongs = YES;
    
    int numEqualAlbums = 0;
    for(int i = 0; i < _allAlbums.count; i++){
        if([_allAlbums[i] isEqual:mysteryArtist.allAlbums[i]])
            numEqualAlbums++;
    }
    if(_allAlbums.count == numEqualAlbums)
        uniqueAlbums = NO;
    else
        uniqueAlbums = YES;

    return (sameName && (uniqueSongs || uniqueAlbums)) ? YES : NO;
}

-(NSUInteger)hash {
    NSUInteger result = 1;
    NSUInteger prime = 31;
    //NSUInteger yesPrime = 1231;
    //NSUInteger noPrime = 1237;
    
    // Add any object that already has a hash function (NSString)
    result = prime * result + [self.artistName hash];
    result = prime * result + [_allSongs hash];
    result = prime * result + [_allAlbums hash];
    
    // Add primitive variables (int)
    //result = prime * result + self.genreCode;
    
    // Boolean values (BOOL)
    //result = prime * result + self.isSelected ? yesPrime : noPrime;
    
    return result;
}

@end