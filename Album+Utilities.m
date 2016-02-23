//
//  Album+Utilities.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/16/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Album+Utilities.h"

@implementation Album (Utilities)
NSString * const ALBUM_SONGS_KEY = @"albumSongs";
NSString * const ARTIST_KEY = @"artist";

- (void)setAlbumSongs:(NSSet *)albumSongs
{
    if(albumSongs.count == 0){
        [Album deleteAlbumWithDelay:self];
    }
    [self willChangeValueForKey:ALBUM_SONGS_KEY];
    [self setPrimitiveValue:albumSongs forKey:ALBUM_SONGS_KEY];
    [self didChangeValueForKey:ALBUM_SONGS_KEY];
}

+ (void)deleteAlbumWithDelay:(Album *)album
{
    double delayInSeconds = 1;
    __weak Album *anAlbum = album;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        //code to be executed on the main queue after delay
        [[CoreDataManager context] deleteObject:anAlbum];
    });
}

+ (Album *)createNewAlbumWithName:(NSString *)name usingSong:(Song *)newSong inManagedContext:(NSManagedObjectContext *)context
{
    if(context == nil || name == nil)
        return nil;
    Album *album = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext:context];
    album.uniqueId = [[NSObject UUID] copy];
    album.albumName = name;
    album.smartSortAlbumName = [name regularStringToSmartSortString];
    if(album.smartSortAlbumName.length == 0)  //edge case,if name itself is something like 'the', dont remove all chars! Keep original name.
        album.smartSortAlbumName = name;
    album.albumArt = [NSEntityDescription insertNewObjectForEntityForName:@"AlbumAlbumArt"
                                                   inManagedObjectContext:context];
    return album;
}

+ (void)updateAlbumSmartSortName:(Album *)anAlbum
{
    NSString *originalSmartSortName = anAlbum.albumName;
    anAlbum.smartSortAlbumName = [anAlbum.albumName regularStringToSmartSortString];
    if(anAlbum.smartSortAlbumName.length == 0)  //edge case,if name itself is something like 'the', dont remove all chars! Keep original name.
        anAlbum.smartSortAlbumName = originalSmartSortName;
}

+ (BOOL)isAlbum:(Album *)album1 equalToAlbum:(Album *)album2
{
    if(album1 == album2)
        return YES;
    if([[album1 uniqueId] isEqualToString:[album2 uniqueId]])
        return YES;
    
    return NO;
}

@end
