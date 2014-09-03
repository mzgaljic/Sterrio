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
                        inGenre:(int)genreCode
               inManagedContext:(NSManagedObjectContext *)context
{
    if(context == nil)
        return nil;
    Song *newSong = [Song createNewSongWithName:songName inManagedContext:context];
    Album *newOrExistingAlbum;
    Artist *newOrExistingArtist;
    
    if([GenreConstants isValidGenreCode:genreCode])
        newSong.genreCode = [NSNumber numberWithInt:genreCode];
    else
        newSong.genreCode = [NSNumber numberWithInt:[GenreConstants noGenreSelectedGenreCode]];
    
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

        if(albumOrAlbumName){  //need to avoid duplicate songs
            NSArray *standAloneSongs = [newOrExistingArtist.standAloneSongs allObjects];
            if([standAloneSongs containsObject:newSong]){
                NSMutableSet *mutableSet = [NSMutableSet setWithSet:newOrExistingArtist.standAloneSongs];
                [mutableSet removeObject:newSong];
                newOrExistingArtist.standAloneSongs = mutableSet;
            }
        }
        
        newSong.artist = newOrExistingArtist;
    }
    return newSong;
}

+ (BOOL)areSongsEqual:(NSArray *)arrayOfTwoSongObjects
{
    if(arrayOfTwoSongObjects.count == 2){
        if([[arrayOfTwoSongObjects[0] song_id] isEqualToString:[arrayOfTwoSongObjects[1] song_id]])
            return YES;
    }
    return NO;
}

- (BOOL)setAlbumArt:(UIImage *)image
{
    BOOL success = NO;
    NSString *artFileName;
    if(image == nil){
        if(self.albumArtFileName != nil)
            [self removeAlbumArt];
        return YES;
    }
    
    if(! [self.associatedWithAlbum boolValue]){
        artFileName = [NSString stringWithFormat:@"%@.png", self.song_id];
        
        //save the UIImage to disk
        if([AlbumArtUtilities isAlbumArtAlreadySavedOnDisk: artFileName])
            success = YES;
        else
            success = [AlbumArtUtilities saveAlbumArtFileWithName:artFileName andImage:image];
    }
    else if(self.album.albumArtFileName)
        artFileName = self.album.albumArtFileName;
    else{
        [self.album setAlbumArt:image];
        artFileName = self.album.albumArtFileName;
    }
    
    self.albumArtFileName = artFileName;
    return success;
}

- (void)removeAlbumArt
{
    if(self.albumArtFileName){
        if(! [self.associatedWithAlbum boolValue]){  //can definitely remove the image
            //remove file from disk
            [AlbumArtUtilities deleteAlbumArtFileWithName:self.albumArtFileName];
            
            //made albumArtFileName property nil
            self.albumArtFileName = nil;
        }
        else{
            //we don't want to touch the album artwork if this song is part of an album.
            self.albumArtFileName = nil;
        }
    }
}

#pragma mark - Code For Custom setters/KVO
/*
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
    [self addObserver:self forKeyPath:@"album" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
    [self addObserver:self forKeyPath:@"artist" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"album"]){
        Album *newValue = [change objectForKey:NSKeyValueChangeNewKey];
        [SongModelHandler handleAlbumChange:self newAlbum:newValue];
        
    } else if([keyPath isEqualToString:@"artist"]){
        Artist *newValue = [change objectForKey:NSKeyValueChangeNewKey];
        [SongModelHandler handleArtistChange:self newArtist:newValue];
    }
}

- (void)willTurnIntoFault
{
    [self removeObserver:self forKeyPath:@"album"];
    [self removeObserver:self forKeyPath:@"artist"];
}
 */

#pragma mark - private implementation
+ (Song *)createNewSongWithName:(NSString *)name inManagedContext:(NSManagedObjectContext *)context
{
    Song *song = [NSEntityDescription insertNewObjectForEntityForName:@"Song" inManagedObjectContext:context];
    song.song_id = [[NSObject UUID] copy];
    song.songName = name;
    song.smartSortSongName = [name regularStringToSmartSortString];
    if(song.smartSortSongName.length == 0)  //edge case...if name itself is just something like 'the', dont remove all characters! Keep original name.
        song.smartSortSongName = name;
    return song;
}

@end
