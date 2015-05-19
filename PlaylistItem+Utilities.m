//
//  PlaylistItem+Utilities.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/4/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "PlaylistItem+Utilities.h"
#import "NSObject+ObjectUUID.h"

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
- (void)prepareForDeletion
{
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
}

@end
