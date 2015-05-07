//
//  PlayableItem.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlayableItem : NSObject

@property (nonatomic, assign, readonly) BOOL isFromUpNextSongs;

- (Song *)songForItem;
- (PlaylistItem *)playlistItemForItem;
- (PlaybackContext *)contextForItem;

- (instancetype)initWithSong:(Song *)aSong
                     context:(PlaybackContext *)context
             fromUpNextSongs:(BOOL)upNextSong;

- (instancetype)initWithPlaylistItem:(PlaylistItem *)playlistItem
                             context:(PlaybackContext *)context
                     fromUpNextSongs:(BOOL)upNextSong;

- (BOOL)isEqualToSong:(Song *)aSong withContext:(PlaybackContext *)context;
- (BOOL)isEqualToPlaylistItem:(PlaylistItem *)item withContext:(PlaybackContext *)context;
- (BOOL)isEqualToItem:(PlayableItem*)item;

@end
