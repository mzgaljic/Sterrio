//
//  Artist+Utilities.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/16/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Artist+Utilities.h"

@implementation Artist (Utilities)

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

+ (BOOL)isArtist:(Artist *)artist1 equalToArtist:(Artist *)artist2
{
    if(artist1 == artist2)
        return YES;
    if([[artist1 artist_id] isEqualToString:[artist2 artist_id]])
        return YES;
    
    return NO;
}

@end
