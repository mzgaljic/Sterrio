
//
//  PlayableItem.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "PlayableItem.h"
#import "PlaylistItem.h"
#import "NSObject+ObjectUUID.h"

@interface PlayableItem ()
@property (nonatomic, strong, readonly) Song *song;
@property (nonatomic, strong, readonly) PlaylistItem *playlistItem;
@property (nonatomic, strong, readonly) PlaybackContext *context;
@end
@implementation PlayableItem

- (Song *)songForItem
{
    if(_song != nil)
        return _song;
    
    if(_playlistItem != nil)
        return _playlistItem.song;
    
    return nil;
}

- (PlaylistItem *)playlistItemForItem
{
    return _playlistItem;
}

- (PlaybackContext *)contextForItem
{
    return _context;
}

- (instancetype)initWithSong:(Song *)aSong
                     context:(PlaybackContext *)context
             fromUpNextSongs:(BOOL)upNextSong
{
    if(self = [super init]){
        _song = aSong;
        _isFromUpNextSongs = upNextSong;
        _context = context;
    }
    return self;
}

- (instancetype)initWithPlaylistItem:(PlaylistItem *)playlistItem
                             context:(PlaybackContext *)context
                     fromUpNextSongs:(BOOL)upNextSong
{
    if(self = [super init]){
        _playlistItem = playlistItem;
        _isFromUpNextSongs = upNextSong;
        _context = context;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if(self == object)
        return YES;
    
    if([object isMemberOfClass:[PlayableItem class]]){
        PlayableItem *otherItem = (PlayableItem *)object;
        return [self isEqualToItem:otherItem];
    }
    
    return NO;
}

- (BOOL)isEqualToSong:(Song *)aSong withContext:(PlaybackContext *)context
{
    BOOL sameSongIDs = [_song.uniqueId isEqualToString:aSong.uniqueId];
    BOOL sameContexts = ([_context isEqualToContext:context]
                         || (_context == nil && context == nil));
    return (sameSongIDs && sameContexts);
}

- (BOOL)isEqualToPlaylistItem:(PlaylistItem *)item withContext:(PlaybackContext *)context
{
    BOOL samePlaylistItemIDs = [_playlistItem.uniqueId isEqualToString:item.uniqueId];
    BOOL sameContexts = ([_context isEqualToContext:context]
                         || (_context == nil && context == nil));
    return (samePlaylistItemIDs && sameContexts);
}

- (BOOL)isEqualToItem:(PlayableItem *)item
{
    if(_song)
    {
        if(item.songForItem)
        {
            return [_song.uniqueId isEqualToString:item.songForItem.uniqueId];
        }
    }
    else if(_playlistItem)
    {
        if(item.playlistItem)
        {
            return [_playlistItem.uniqueId isEqualToString:item.playlistItem.uniqueId];
        }
    }
    return NO;
}

@end
