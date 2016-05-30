//
//  PlaylistItem+Utilities.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/4/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "PlaylistItem+Utilities.h"
#import "NSObject+ObjectUUID.h"
#import "CoreDataManager.h"

@implementation PlaylistItem (Utilities)

+ (PlaylistItem *)createNewPlaylistItemWithCorrespondingPlaylist:(Playlist *)aPlaylist
                                                            song:(Song *)aSong
                                                 indexInPlaylist:(short)index
                                                inManagedContext:(NSManagedObjectContext *)context
{
    if(context == nil || aPlaylist == nil || aSong == nil)
        return nil;
    
    PlaylistItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"PlaylistItem"
                                                          inManagedObjectContext:context];
    newItem.uniqueId = [[NSObject UUID] copy];
    newItem.song = aSong;
    newItem.index = [NSNumber numberWithShort:index];
    newItem.creationDate = [[NSDate alloc] init];
    
    return newItem;
}

- (BOOL)isEqualToPlaylistItem:(PlaylistItem *)item
{
    if(self == item)
        return YES;
    
    return ([self.uniqueId isEqualToString:item.uniqueId]) ? YES : NO;
}

//custom logic to keep existing PlaylistItem indexes valid if songs are deleted from the library
//custom logic to delete the underlying song if the user wanted it to only be visible in 1 playlist.
- (void)prepareForDeletion
{
    __block NSManagedObjectContext *context = [self managedObjectContext];
    if(context == nil) {
        context = [CoreDataManager context];
    }
    
    //NOTE: Normally when a PlaylistItem is deleted, the 'nullify' delete rule takes place.
    //The song will remain in the general library and only be gone from the playlist. If the user
    //wanted this song to only be visible from a particular playlist, then we need to perform additional
    //work here to avoid an 'orphaned record' in core data. Particular - having Song entities floating
    //around without the user ever knowing.
    __block BOOL deleteSongWithDelay = NO;
    if(self.song.smartSortSongName == nil) {
        //user only wanted it visible in this playlist.
        deleteSongWithDelay = YES;
    }
    
    //NOTE: Here is the 'most common/normal' PlaylistItem delete logic...
    //the index of every PlaylistItem after this one will be screwed up once this is deleted. fix that...
    Playlist *playlist = self.playlist;
    
    short removedIndex = [self.index shortValue];
    
    if(playlist.playlistItems.count == 0)  //occurs when deleting entire playlist (cascade delete rule...)
        return;
    
    NSMutableArray *allItems = [NSMutableArray arrayWithArray:[playlist.playlistItems allObjects]];
    //remove the deleted item
    NSUInteger indexInArray = [allItems indexOfObjectIdenticalTo:self];
    [allItems removeObjectAtIndex:indexInArray];
    
    NSPredicate *itemsAfterPredicate;
    itemsAfterPredicate = [NSPredicate predicateWithFormat:@"index > %i", removedIndex];
    NSArray *itemsAfter = [allItems filteredArrayUsingPredicate:itemsAfterPredicate];
    
    //decrement all items after the deleted one to fill the "gap".
    [itemsAfter enumerateObjectsUsingBlock:^(PlaylistItem *item, NSUInteger idx, BOOL *stop) {
        NSUInteger indexInArray = [allItems indexOfObjectIdenticalTo:item];
        item.index = [NSNumber numberWithShort:[item.index shortValue] -1];
        [allItems replaceObjectAtIndex:indexInArray withObject:item];
    }];
    
    playlist.playlistItems = [NSSet setWithArray:allItems];
    //end PlaylistItem incrementing logic.
    
    if(deleteSongWithDelay) {
        int delaySeconds = 1;
        __weak __block Song *weakSong = self.song;
        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, delaySeconds * NSEC_PER_SEC);
        dispatch_after(delayTime, dispatch_get_main_queue(), ^(void) {
            NSLog(@"Deleting song w/ name: '%@' from entire library.", weakSong.songName);
            [context deleteObject:weakSong];
            context = nil;
        });
    }
}

@end
