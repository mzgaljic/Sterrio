//
//  Album+Utilities.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/16/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Album+Utilities.h"

@implementation Album (Utilities)
static void *albumSongsChanged = &albumSongsChanged;


+ (Album *)createNewAlbumWithName:(NSString *)name usingSong:(Song *)newSong inManagedContext:(NSManagedObjectContext *)context
{
    if(context == nil || name == nil)
        return nil;
    Album *album = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext:context];
    album.album_id = [[NSObject UUID] copy];
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
    if([[album1 album_id] isEqualToString:[album2 album_id]])
        return YES;
    
    return NO;
}

@end
