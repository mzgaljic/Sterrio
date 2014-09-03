//
//  AlbumModelHandler.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/19/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AlbumModelHandler.h"

@implementation AlbumModelHandler

+ (void)handleArtistChangeUsingAlbum:(Album *)album newArtist:(Artist *)artist
{
    BOOL canContinue = [AlbumModelHandler logExecutionTimeForAlbumsChange];
    if(canContinue)
    {
        NSMutableSet *mutableSet = [NSMutableSet setWithSet:album.artist.albums];
        [mutableSet removeObject:album];
        album.artist.albums = mutableSet;
        
        
        if(! [artist.albums containsObject:album])
            artist.albums = [artist.albums setByAddingObject:album];
        if(album.artist.standAloneSongs.count == 0 && album.artist.albums.count ==0)
            [[CoreDataManager context] deleteObject:album.artist];
        
        album.artist = artist;
    }
}

static NSDate *lastTime_albums;
+ (BOOL)logExecutionTimeForAlbumsChange
{
    if(lastTime_albums == nil){
        lastTime_albums = [NSDate date];
        return YES;
    }
    
    NSDate *currentTime = [NSDate date];
    NSTimeInterval executionTime = [currentTime timeIntervalSinceDate:lastTime_albums];
    NSLog(@"executionTime = %f", executionTime);
    if(executionTime <= 1)
        return NO;
    else
        return YES;
}


@end
