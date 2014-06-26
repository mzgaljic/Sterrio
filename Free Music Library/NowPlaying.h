//
//  NowPlaying.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/27/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"
#import "Playlist.h"

@interface NowPlaying : NSObject
@property(atomic, readonly) BOOL playing;
@property(atomic, readonly) BOOL paused;

///nil if no songs played/chosen yet.
@property(atomic, strong, readonly) Song *aSong;
///Nil if the now playing song isn't from a playlist!
@property(atomic, strong, readonly) Playlist *originatingPlaylist;

- (void)updateNowPlayingWithSong:(Song *)nextSong fromOptionalPlaylist:(Playlist *)newOrSamePlaylist;
- (void)ResumeNowPlaying;
- (void)PauseNowPlaying;

@end
