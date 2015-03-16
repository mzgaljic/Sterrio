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

@interface NowPlayingSong : NSObject

@property (nonatomic, strong) Song *nowPlaying;
@property (nonatomic, strong) PlaybackContext *context;
@property (nonatomic, assign, readonly) BOOL isFromPlayNextSongs;

+ (instancetype)sharedInstance;

- (BOOL)isEqualToSong:(Song *)aSong compareWithContext:(PlaybackContext *)context;

- (void)setNewNowPlayingSong:(Song *)newSong
                     context:(PlaybackContext *)context;

- (void)setPlayingBackFromPlayNextSongs:(BOOL)isTrue;

@end
