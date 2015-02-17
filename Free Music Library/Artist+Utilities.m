//
//  Artist+Utilities.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/16/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Artist+Utilities.h"

@implementation Artist (Utilities)
static void *standAloneSongsDidChange = &standAloneSongsDidChange;
static void *albumsDidChange = &albumsDidChange;

#pragma mark - Code For Custom setters/KVO (just standaloneSongs)
- (void)awakeFromInsert
{
    [self observeStuff];
}

- (void)awakeFromFetch
{
    [self observeStuff];
}

- (void)observeStuff
{
    [self addObserver:self
           forKeyPath:@"standAloneSongs"
              options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
              context:standAloneSongsDidChange];
    [self addObserver:self
           forKeyPath:@"albums"
              options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
              context:albumsDidChange];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(context == albumsDidChange){
        //is this artist garbage now?
        if(! [AppEnvironmentConstants isUserEditingSongOrAlbumOrArtist])
            [self deleteThisArtistIfNecessaryUsingArtistID:self.artist_id];
    }
    else if (context == standAloneSongsDidChange){
        NSSet *standAloneSongs = [change objectForKey:NSKeyValueChangeNewKey];
        
        //is this artist garbage now?
        [self deleteThisArtistIfNecessaryUsingArtistID:self.artist_id];
        
        //check if this artist has an album with this song already (VERY inefficient, but its ok since the data set is small 99.99% of the time)
        NSSet *artistAlbums = self.albums;
        BOOL songAlreadyInAlbum = NO;
        Song *matchedItem;
        for(Song *aStandAloneSong in standAloneSongs)
        {
            for(Album *someAlbum in artistAlbums)
            {
                for(Song *aSong in someAlbum.albumSongs)
                {
                    if([aSong.song_id isEqualToString:aStandAloneSong.song_id]){
                        songAlreadyInAlbum = YES;
                        matchedItem = aStandAloneSong;
                        break;
                    }
                }
            }
        }
        if(songAlreadyInAlbum)
        {
            NSMutableSet *mutableSet = [NSMutableSet setWithSet:standAloneSongs];
            [mutableSet removeObject:matchedItem];
            self.standAloneSongs = mutableSet;  //will unfortunately recursively call this method. but this should only occur once at MOST.
        }
        
        //check if a song has been nullified (which means a song entity was deleted, and its delete rule nullifies the pointer)
        Song *deletedSong;
        NSArray *standAloneSongsArray = [standAloneSongs allObjects];
        for(int i = 0; i < standAloneSongsArray.count; i++)
        {
            if(standAloneSongsArray[i] == nil)  //found the deleted song
            {
                deletedSong = standAloneSongsArray[i];
                break;
            }
        }
        //remove the song from the data model
        if(deletedSong != nil)
        {
            [[CoreDataManager context] deleteObject:deletedSong];
            [[CoreDataManager sharedInstance] saveContext];
        }
    } else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)deleteThisArtistIfNecessaryUsingArtistID:(NSString *)artistID
{
    if(self.standAloneSongs.count == 0 && self.albums.count == 0)
        [self deleteThisArtistAfterDelayUsingArtistId:self.artist_id];
}

- (void)deleteThisArtistAfterDelayUsingArtistId:(NSString *)artistID
{
    double delayInSeconds = 0.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        // code to be executed on main thread.
        
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Artist" inManagedObjectContext:[CoreDataManager context]];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"artist_id == %@", artistID];
        [request setPredicate:predicate];
        
        NSError *error;
        NSArray *matchingData = [[CoreDataManager context] executeFetchRequest:request error:&error];
        if(matchingData.count == 1)
            [[CoreDataManager context] deleteObject:matchingData[0]];
        [[CoreDataManager sharedInstance] saveContext];
    });
}

- (void)willTurnIntoFault
{
    [self removeObserver:self forKeyPath:@"standAloneSongs" context:standAloneSongsDidChange];
    [self removeObserver:self forKeyPath:@"albums" context:albumsDidChange];
}


#pragma mark - implementation
//when no album was created
+ (Artist *)createNewArtistWithName:(NSString *)name inManagedContext:(NSManagedObjectContext *)context
{
    if(context == nil || name == nil)
        return nil;
    Artist *artist = [NSEntityDescription insertNewObjectForEntityForName:@"Artist" inManagedObjectContext:context];
    artist.artist_id = [[NSObject UUID] copy];
    artist.artistName = name;
    artist.smartSortArtistName = [name regularStringToSmartSortString];
    return artist;
}

//when an artist was created witht the song and album
+ (Artist *)createNewArtistWithName:(NSString *)name
                         usingAlbum:(Album *)anAlbum
                   inManagedContext:(NSManagedObjectContext *)context
{
    if(context == nil || name == nil)
        return nil;
    Artist *artist = [NSEntityDescription insertNewObjectForEntityForName:@"Artist" inManagedObjectContext:context];
    artist.artist_id = [[NSObject UUID] copy];
    artist.artistName = name;
    artist.smartSortArtistName = [name regularStringToSmartSortString];
    if(artist.smartSortArtistName.length == 0)  //edge case,if name itself is something like 'the', dont remove all chars! Keep original name.
        artist.smartSortArtistName = name;
    anAlbum.artist = artist;
    
    return artist;
}

+ (BOOL)areArtistsEqual:(NSArray *)arrayOfTwoArtistObjects
{
    if(arrayOfTwoArtistObjects.count == 2){
        if([[arrayOfTwoArtistObjects[0] artist_id] isEqualToString:[arrayOfTwoArtistObjects[1] artist_id]])
            return YES;
    }
    return NO;
}
@end
