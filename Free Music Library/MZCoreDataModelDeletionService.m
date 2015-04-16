//
//  MZCoreDataModelDeletionService.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/10/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZCoreDataModelDeletionService.h"

@implementation MZCoreDataModelDeletionService

+ (void)prepareSongForDeletion:(Song *)songToDelete
{
    //remove song from its album (and delete the album too)...if applicable
    [MZCoreDataModelDeletionService removeSongFromItsAlbum:songToDelete];
    
    //now do the same with the songs artist
    [MZCoreDataModelDeletionService removeSongFromItsArtist:songToDelete];
    
    [songToDelete removeAlbumArt];
}

+ (void)deleteArtistInManagedObjectContextWithoutSave:(Artist *)artistToDelete
{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Artist"
                                                  inManagedObjectContext:[CoreDataManager context]];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"artist_id == %@", artistToDelete.artist_id];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *matchingData = [[CoreDataManager context] executeFetchRequest:request error:&error];
    if(matchingData.count == 1)
        [[CoreDataManager context] deleteObject:matchingData[0]];
}

+ (void)removeSongFromItsAlbum:(Song *)aSong
{
    Album *songAlbum = aSong.album;
    if(songAlbum)
    {
        if(songAlbum.albumSongs.count == 1)
            aSong.album = nil;
        else
        {
            NSMutableSet *mutableSet = [NSMutableSet setWithSet:songAlbum.albumSongs];
            [mutableSet removeObject:aSong];
            songAlbum.albumSongs = mutableSet;
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
        
        if(numArtistSongs == 1)
            [MZCoreDataModelDeletionService deleteArtistInManagedObjectContextWithoutSave:songArtist];
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
    }
}

@end
