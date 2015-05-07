//
//  NowPlayingSong.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/20/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"
#import "Artist.h"
#import "Album.h"
#import "Playlist.h"
#import "PlaybackContext.h"

@class PlayableItem;
@interface NowPlayingSong : NSObject

@property (nonatomic, strong) PlayableItem *nowPlayingItem;

+ (instancetype)sharedInstance;

- (BOOL)isEqualToItem:(PlayableItem *)anItem;

- (void)setNewNowPlayingItem:(PlayableItem *)newItem;

@end
