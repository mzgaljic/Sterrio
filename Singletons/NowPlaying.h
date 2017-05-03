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
@interface NowPlaying : NSObject

@property (nonatomic, strong, readonly) PlayableItem *playableItem;

+ (instancetype)sharedInstance;

- (BOOL)isEqualToItem:(PlayableItem *)anItem;

- (void)setNewPlayableItem:(PlayableItem *)newItem;

@end
