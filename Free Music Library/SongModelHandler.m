//
//  SongModelHandler.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/19/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "SongModelHandler.h"

@implementation SongModelHandler

+ (void)handleAlbumChange:(Song *)selfSong newAlbum:(Album *)newAlbum
{
    BOOL canContinue = [SongModelHandler logExecutionTimeForAlbumChange];  //this is to prevent repetitive calls from kvo, and limit it to what is reasonably,one transaction
    if(canContinue)
    {
        if(newAlbum == nil){  //unAssociating this song from an album
            //needed so that when the old associated album is deleted, this song still has its art.
            [SongModelHandler makeCopyOfArtAndRenameUsingSong:selfSong];
            selfSong.associatedWithAlbum = [NSNumber numberWithBool:NO];
            
        }
        else if([Album areAlbumsEqual:[NSArray arrayWithObjects:selfSong.album, newAlbum, nil]] || [newAlbum isEqual:[NSNull null]])
            return;
        else
        {  //associating the album with this song
            //when this song is associated w/ an album, add this song to its albumSongs
            [selfSong.album.albumSongs setByAddingObject:selfSong];
            selfSong.associatedWithAlbum = [NSNumber numberWithBool:YES];
            
            //finally, override old album art file name...possibly deleting the old album art if the two vary.
            //check if album has album art already. if not, make this the default for the album!
            if(selfSong.album.albumArtFileName){
                BOOL onDisk = [AlbumArtUtilities isAlbumArtAlreadySavedOnDisk:[NSString stringWithFormat:@"%@.jpg", selfSong.song_id]];
                //old album art (from this song before it was linked to the album) is on disk
                if(onDisk)
                    [selfSong removeAlbumArt];
            }else{
                //reuse the album art as the new art for the album. Rename the file on disk though!
                [AlbumArtUtilities renameAlbumArtFileFrom:[NSString stringWithFormat:@"%@.jpg", selfSong.song_id]
                                                       to:[NSString stringWithFormat:@"%@.jpg", selfSong.album.album_id]];
                [selfSong.album setAlbumArt:[AlbumArtUtilities albumArtFileNameToUiImage:[NSString stringWithFormat:@"%@.jpg", selfSong.album.album_id]]];
            }
            selfSong.albumArtFileName = selfSong.album.albumArtFileName;
            
            //this song will now automatically appear under allAlbums array, so remove it from allSongs (that is for songs NOT associated with albums)
            if(selfSong.artist){
                NSMutableSet *mutableSet = [NSMutableSet setWithSet:[selfSong.artist standAloneSongs]];
                [mutableSet removeObject:selfSong];
                selfSong.artist.standAloneSongs = mutableSet;
            }
        }
    }
}

+ (void)handleArtistChange:(Song *)selfSong newArtist:(Artist *)artist
{
    if([artist isEqual:[NSNull null]])
        return;
    BOOL canContinue = [SongModelHandler logExecutionTimeForArtistChange];
    if(canContinue)
    {
        if([selfSong.associatedWithAlbum boolValue]){
            NSMutableSet *mutableSet = [NSMutableSet setWithSet:selfSong.artist.albums];
            [mutableSet removeObject:selfSong.album];
            selfSong.artist.albums = mutableSet;
            
            mutableSet = [NSMutableSet setWithSet:selfSong.artist.standAloneSongs];
            [mutableSet removeObject:selfSong];
            selfSong.artist.standAloneSongs = mutableSet;
            
            if(selfSong.artist.standAloneSongs.count == 0 && selfSong.artist.albums.count ==0)
                if(selfSong != nil)
                    if(selfSong.artist != nil)
                        [[CoreDataManager context] deleteObject:selfSong.artist];
            
        }else{
            //if current songs artist differs from new one, remove myself from that artists list before
            //adding myself to the new artists songs list.
            NSMutableSet *mutableSet = [NSMutableSet setWithSet:selfSong.artist.standAloneSongs];
            [mutableSet removeObject:selfSong];
            
            selfSong.artist.standAloneSongs = mutableSet;
            
            if(! [artist.standAloneSongs containsObject:selfSong])
                artist.standAloneSongs = [artist.standAloneSongs setByAddingObject:selfSong];
            
            if(selfSong.artist.standAloneSongs.count == 0 && selfSong.artist.albums.count == 0)
                if(selfSong != nil || selfSong.artist != nil)
                        [[CoreDataManager context] deleteObject:selfSong.artist];
        }
        
        selfSong.artist = artist;
    }
}

//private
+ (BOOL)makeCopyOfArtAndRenameUsingSong:(Song *)selfSong
{
    return [AlbumArtUtilities makeCopyOfArtWithName:[NSString stringWithFormat:@"%@.jpg", selfSong.album.album_id]
                                          andNameIt:[NSString stringWithFormat:@"%@.jpg", selfSong.song_id]];
}

static NSDate *lastTime_artist;
static NSDate *lastTime_album;
+ (BOOL)logExecutionTimeForArtistChange
{
    if(lastTime_artist == nil){
        lastTime_artist = [NSDate date];
        return YES;
    }
    
    NSDate *currentTime = [NSDate date];
    NSTimeInterval executionTime = [currentTime timeIntervalSinceDate:lastTime_artist];
    NSLog(@"executionTime = %f", executionTime);
    if(executionTime <= 1)
        return NO;
    else
        return YES;
}

+ (BOOL)logExecutionTimeForAlbumChange
{
    if(lastTime_album == nil){
        lastTime_album = [NSDate date];
        return YES;
    }
    
    NSDate *currentTime = [NSDate date];
    NSTimeInterval executionTime = [currentTime timeIntervalSinceDate:lastTime_album];
    NSLog(@"executionTime = %f", executionTime);
    if(executionTime <= 1)
        return NO;
    else
        return YES;
}

@end
