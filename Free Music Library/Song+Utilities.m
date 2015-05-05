//
//  Song+Utilities.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/16/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Song+Utilities.h"

@implementation Song (Utilities)
+ (Song *)createNewSongWithName:(NSString *)songName
           inNewOrExistingAlbum:(id)albumOrAlbumName
          byNewOrExistingArtist:(id)artistOrArtistName
               inManagedContext:(NSManagedObjectContext *)context
                   withDuration:(NSInteger)durationInSeconds
{
    if(context == nil)
        return nil;
    Song *newSong = [Song createNewSongWithName:songName inManagedContext:context];
    newSong.duration = [NSNumber numberWithInteger:durationInSeconds];
    Album *newOrExistingAlbum;
    Artist *newOrExistingArtist;
    
    if(albumOrAlbumName){
        //need to create new album in core data
        if([albumOrAlbumName isKindOfClass:[NSString class]])
        {
            newOrExistingAlbum = [Album createNewAlbumWithName:albumOrAlbumName usingSong:newSong inManagedContext:context];
        }
        else if([albumOrAlbumName isKindOfClass:[Album class]])//else use the existing album object
        {
            newOrExistingAlbum = albumOrAlbumName;
        }
        newSong.album = newOrExistingAlbum;
    }
    
    if(artistOrArtistName){
        //need to create new artist in core data
        if([artistOrArtistName isKindOfClass:[NSString class]])
        {
            if(albumOrAlbumName)
                newOrExistingArtist = [Artist createNewArtistWithName:artistOrArtistName usingAlbum:newOrExistingAlbum inManagedContext:context];
            else
                newOrExistingArtist = [Artist createNewArtistWithName:artistOrArtistName inManagedContext:context];
        }
        else if([artistOrArtistName isKindOfClass:[Artist class]])//else we use the existing artist object
        {
            newOrExistingArtist = artistOrArtistName;
            if(albumOrAlbumName){
                newOrExistingAlbum.artist = newOrExistingArtist;
            }
        }
        newSong.artist = newOrExistingArtist;
    }
    return newSong;
}

+ (BOOL)isSong:(Song *)song1 equalToSong:(Song *)song2
{
    if(song1 == song2)
        return YES;
    if([[song1 uniqueId] isEqualToString:[song2 uniqueId]])
        return YES;
    
    return NO;
}

- (BOOL)isEqualToSong:(Song *)aSong
{
    if(self == aSong)
        return YES;
    if([[self uniqueId] isEqualToString:[aSong uniqueId]])
        return YES;
    
    return NO;
}

#pragma mark - private implementation
+ (Song *)createNewSongWithName:(NSString *)name inManagedContext:(NSManagedObjectContext *)context
{
    Song *song = [NSEntityDescription insertNewObjectForEntityForName:@"Song"
                                               inManagedObjectContext:context];
    song.uniqueId = [[NSObject UUID] copy];
    song.songName = name;
    song.smartSortSongName = [name regularStringToSmartSortString];
    if(song.smartSortSongName.length == 0)  //edge case...if name itself is just something like 'the', dont remove all characters! Keep original name.
        song.smartSortSongName = name;
    return song;
}


+ (Song *)createNewSongWithNoNameAndManagedContext:(NSManagedObjectContext *)context
{
    Song *song = [NSEntityDescription insertNewObjectForEntityForName:@"Song"
                                               inManagedObjectContext:context];
    song.uniqueId = [[NSObject UUID] copy];
    return song;
}

@end
