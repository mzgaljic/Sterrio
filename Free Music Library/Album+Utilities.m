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
    if(newSong)
        newSong.associatedWithAlbum = [NSNumber numberWithBool:YES];
    
    return album;
}

+ (void)updateAlbumSmartSortAndArtFileNames:(Album *)anAlbum
{
    NSString *originalSmartSortName = anAlbum.albumName;
    anAlbum.smartSortAlbumName = [anAlbum.albumName regularStringToSmartSortString];
    if(anAlbum.smartSortAlbumName.length == 0)  //edge case,if name itself is something like 'the', dont remove all chars! Keep original name.
        anAlbum.smartSortAlbumName = originalSmartSortName;
}

+ (BOOL)areAlbumsEqual:(NSArray *)arrayOfTwoAlbumObjects
{
    if(arrayOfTwoAlbumObjects.count == 2){
        if([[arrayOfTwoAlbumObjects[0] album_id] isEqualToString:[arrayOfTwoAlbumObjects[1] album_id]])
            return YES;
    }
    return NO;
}

- (BOOL)setAlbumArt:(UIImage *)image 
{
    BOOL success = NO;
    
    if(image == nil){
        if(self.albumArtFileName != nil)
            [self removeAlbumArt];
        return YES;
    }
    
    NSString *artFileName = [NSString stringWithFormat:@"%@.jpg", self.album_id];
    
    //save the UIImage to disk
    if([AlbumArtUtilities isAlbumArtAlreadySavedOnDisk:artFileName])
        success = YES;
    else{
        success = [AlbumArtUtilities saveAlbumArtFileWithName:artFileName andImage:image];
    }
    
    self.albumArtFileName = artFileName;
    return success;
}

- (void)removeAlbumArt
{
    if(self.albumArtFileName){
        //remove file from disk
        [AlbumArtUtilities deleteAlbumArtFileWithName:self.albumArtFileName];
        
        self.albumArtFileName = nil;
        
        //set this change to all songs in this album as well
        for(Song *albumSong in self.albumSongs){
            [albumSong setAlbumArt:nil];
        }
    }
}

#pragma mark - Code For Custom setters/KVO (observing when album songs goes to 0)
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
    [self addObserver:self
           forKeyPath:@"albumSongs"
              options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
              context:albumSongsChanged];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == albumSongsChanged){
        NSSet *albumSongs = [change objectForKey:NSKeyValueChangeNewKey];
        
        if(albumSongs.count == 0){
            [self removeAlbumArt];
            [self deleteThisAlbumAfterDelayUsingAlbumId: self.album_id];
        } else{
            //check if a song has been nullified (which means a song entity was deleted, and its delete rule nullifies the pointer)
            Song *deletedSong;
            NSArray *albumSongsArray = [albumSongs allObjects];
            for(int i = 0; i < albumSongsArray.count; i++)
            {
                if(albumSongsArray[i] == nil)  //found the deleted song
                {
                    deletedSong = albumSongsArray[i];
                    break;
                }
            }
            //remove the song from the data model
            if(deletedSong != nil)
            {
                [[CoreDataManager context] deleteObject:deletedSong];
                [[CoreDataManager sharedInstance] saveContext];
            }
        }
    } else if([keyPath isEqualToString:@"albumName"]){
        [Album updateAlbumSmartSortAndArtFileNames:self];
        [[CoreDataManager sharedInstance] saveContext];
    } else if([keyPath isEqualToString:@"albumArtFileName"]){
        for(Song *aSong in self.albumSongs)
        {
            aSong.albumArtFileName = self.albumArtFileName;
        }
    } else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)deleteThisAlbumAfterDelayUsingAlbumId:(NSString *)albumID
{
    double delayInSeconds = 0.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        // code to be executed on main thread.
        
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Album" inManagedObjectContext:[CoreDataManager context]];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"album_id == %@", albumID];
        [request setPredicate:predicate];
        
        NSError *error;
        NSArray *matchingData = [[CoreDataManager context] executeFetchRequest:request error:&error];
        if(matchingData.count == 1)
            [[CoreDataManager context] deleteObject:matchingData[0]];
        [[CoreDataManager sharedInstance] saveContext];
    });
}

- (void)willTurnIntoFault
{
    //bad practice but it works. A Sigbart occurs here when editing album info under a song edit (and cancelling the edit).
    @try{
        [self removeObserver:self forKeyPath:@"albumSongs" context:albumSongsChanged];
    }@catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
}

@end
