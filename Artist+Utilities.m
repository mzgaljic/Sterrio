//
//  Artist+Utilities.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/16/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Artist+Utilities.h"

@implementation Artist (Utilities)
NSString * const ARTIST_ALBUMS_KEY = @"albums";
NSString * const STANDALONE_SONGS_KEY = @"standAloneSongs";

- (void)setAlbums:(NSSet *)albums
{
    if(albums.count == 0 && self.standAloneSongs.count == 0){
        [Artist deleteArtistWithDelay:self];
    }
    [self willChangeValueForKey:ARTIST_ALBUMS_KEY];
    [self setPrimitiveValue:albums forKey:ARTIST_ALBUMS_KEY];
    [self didChangeValueForKey:ARTIST_ALBUMS_KEY];
}

- (void)setStandAloneSongs:(NSSet *)standAloneSongs
{
    if(standAloneSongs.count == 0 && self.albums.count == 0){
        [Artist deleteArtistWithDelay:self];
    }
    [self willChangeValueForKey:STANDALONE_SONGS_KEY];
    [self setPrimitiveValue:standAloneSongs forKey:STANDALONE_SONGS_KEY];
    [self didChangeValueForKey:STANDALONE_SONGS_KEY];
}

+ (void)deleteArtistWithDelay:(Artist *)artist
{
    double delayInSeconds = 1;
    __weak Artist *anArtist = artist;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        //code to be executed on the main queue after delay
        [[CoreDataManager context] deleteObject:anArtist];
    });
}

//when no album was created
+ (Artist *)createNewArtistWithName:(NSString *)name inManagedContext:(NSManagedObjectContext *)context
{
    if(context == nil || name == nil)
        return nil;
    Artist *artist = [NSEntityDescription insertNewObjectForEntityForName:@"Artist" inManagedObjectContext:context];
    artist.uniqueId = [[NSObject UUID] copy];
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
    artist.uniqueId = [[NSObject UUID] copy];
    artist.artistName = name;
    artist.smartSortArtistName = [name regularStringToSmartSortString];
    if(artist.smartSortArtistName.length == 0)  //edge case,if name itself is something like 'the', dont remove all chars! Keep original name.
        artist.smartSortArtistName = name;
    anAlbum.artist = artist;
    
    return artist;
}

+ (BOOL)isArtist:(Artist *)artist1 equalToArtist:(Artist *)artist2
{
    if(artist1 == artist2)
        return YES;
    if([[artist1 uniqueId] isEqualToString:[artist2 uniqueId]])
        return YES;
    
    return NO;
}

@end
