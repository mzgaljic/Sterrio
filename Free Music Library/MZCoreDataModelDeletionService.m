//
//  MZCoreDataModelDeletionService.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/10/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZCoreDataModelDeletionService.h"
#import "AlbumAlbumArt.h"
#import "SongAlbumArt.h"

@implementation MZCoreDataModelDeletionService

+ (void)prepareSongForDeletion:(Song *)songToDelete
{
    //remove song from its album (and delete the album too)...if applicable
    [MZCoreDataModelDeletionService removeSongFromItsAlbum:songToDelete];
    
    //now do the same with the songs artist
    [MZCoreDataModelDeletionService removeSongFromItsArtist:songToDelete];
    [[CoreDataManager context] deleteObject:songToDelete.albumArt];
    songToDelete.albumArt = nil;
}

+ (void)prepareAlbumForDeletion:(Album *)anAlbum
{
    //remove album from its artist if applicable (and delete artist if needed)
    [self removeAlbumFromItsArtist:anAlbum];
    [[CoreDataManager context] deleteObject:anAlbum.albumArt];
    anAlbum.albumArt = nil;
}

+ (void)removeSongFromItsAlbum:(Song *)aSong
{
    Album *songAlbum = aSong.album;
    //if song has an artist, move the song into the standalone songs NSSet before deleting the album.
    if(aSong.artist)
    {
        NSMutableSet *mutableSet = [NSMutableSet setWithSet:aSong.artist.standAloneSongs];
        [mutableSet addObject:aSong];
        aSong.artist.standAloneSongs = mutableSet;
    }
    
    if(songAlbum)
    {
        if(songAlbum.albumSongs.count == 1){
            [[CoreDataManager context] deleteObject:songAlbum];
        }
        else
        {
            NSMutableSet *mutableSet = [NSMutableSet setWithSet:songAlbum.albumSongs];
            [mutableSet removeObject:aSong];
            songAlbum.albumSongs = mutableSet;
            songAlbum.albumArt.isDirty = @YES;
        }
        
        aSong.album = nil;
    }
}

+ (void)removeAlbumFromItsArtist:(Album *)album
{
    Artist *artist = album.artist;
    if(artist)
    {
        NSMutableSet *mutableSet = [NSMutableSet setWithSet:artist.albums];
        [mutableSet removeObject:album];
        artist.albums = mutableSet;
        
        NSUInteger standAloneSongCount = artist.standAloneSongs.count;
        if(artist.albums.count == 0 && standAloneSongCount == 0){
            [[CoreDataManager context] deleteObject:artist];
        }
    }
}

+ (void)removeSongFromItsArtist:(Song *)aSong
{
    Artist *songArtist = aSong.artist;
    if(songArtist)
    {
        NSUInteger numArtistSongs = 0;
        numArtistSongs += songArtist.standAloneSongs.count;
        for(Album *anAlbum in songArtist.albums)
            numArtistSongs += anAlbum.albumSongs.count;
        
        if(numArtistSongs == 1){
            
            for(Album *artistAlbum in songArtist.albums)
            {
                [self removeAlbumFromItsArtist:artistAlbum];
                artistAlbum.artist = nil;
            }
            
            [[CoreDataManager context] deleteObject:songArtist];
        }
        else
        {
            NSMutableSet *mutableSet = [NSMutableSet setWithSet:songArtist.standAloneSongs];
            BOOL songIsStandalone = [[mutableSet valueForKeyPath:@"objectID"] containsObject:aSong.objectID];
            
            if(songIsStandalone)
            {
                [mutableSet removeObject:aSong];
                songArtist.standAloneSongs = mutableSet;
            }
            else
            {
                for(Album *anAlbum in songArtist.albums){
                    NSMutableSet *mutableSet = [NSMutableSet setWithSet:anAlbum.albumSongs];
                    BOOL songIsInThisAlbum = [[mutableSet valueForKeyPath:@"objectID"] containsObject:aSong.objectID];
                    
                    if(songIsInThisAlbum)
                    {
                        [mutableSet removeObject:aSong];
                        anAlbum.albumSongs = mutableSet;
                    }
                }
            }
        }
        
        aSong.artist = nil;
    }
}

@end
