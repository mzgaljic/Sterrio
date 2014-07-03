//
//  ModelAlteredStatus.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "ModelAlteredStatus.h"
#define SONG_MODEL_HAS_CHANGED_KEY @"songModelHasChanged"
#define ALBUM_MODEL_HAS_CHANGED_KEY @"albumModelHasChanged"
#define ARTIST_MODEL_HAS_CHANGED_KEY @"artistModelHasChanged"

@implementation ModelAlteredStatus
@synthesize SongModelHasChanged = _SongModelHasChanged, AlbumModelHasChanged = _AlbumModelHasChanged, ArtistModelHasChanged = _ArtistModelHasChanged;

+ (instancetype)createSingleton
{
    static id sharedMyModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyModel = [[self alloc] init];
    });
    return sharedMyModel;
}

- (void)setSongModelChangedStatus:(BOOL)modelChangedBool
{
    _SongModelHasChanged = modelChangedBool;
}

- (void)setAlbumModelChangedStatus:(BOOL)modelChangedBool
{
    _AlbumModelHasChanged = modelChangedBool;
}

- (void)setArtistModelChangedStatus:(BOOL)modelChangedBool
{
    _ArtistModelHasChanged = modelChangedBool;
}

//-----------------NSCoding stuff---------------
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        _SongModelHasChanged = [aDecoder decodeBoolForKey:SONG_MODEL_HAS_CHANGED_KEY];
        _AlbumModelHasChanged = [aDecoder decodeBoolForKey:ALBUM_MODEL_HAS_CHANGED_KEY];
        _ArtistModelHasChanged = [aDecoder decodeBoolForKey:ARTIST_MODEL_HAS_CHANGED_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeBool:_SongModelHasChanged forKey:SONG_MODEL_HAS_CHANGED_KEY];
    [aCoder encodeBool:_AlbumModelHasChanged forKey:ALBUM_MODEL_HAS_CHANGED_KEY];
    [aCoder encodeBool:_ArtistModelHasChanged forKey:ARTIST_MODEL_HAS_CHANGED_KEY];
}

+ (ModelAlteredStatus *)loadDataFromDisk
{
    NSData *data = [NSData dataWithContentsOfURL:[FileIOConstants createSingleton].ModelAlteredStateFileUrl];
    if(!data){
        //if class not instantiated before,(file not yet written to disk), return nil
        return nil;
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];  //decode loaded data
}

- (BOOL)saveDataToDisk
{
    ModelAlteredStatus *thisInstance = self;
    
    //save to disk
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:thisInstance];  //encode this class
    return [fileData writeToURL:[FileIOConstants createSingleton].ModelAlteredStateFileUrl atomically:YES];
}

@end
