//
//  PreliminaryNowPlaying.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/14/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//
//This is simply a helper class that is used to assist communication between the private queues and the main playback queue.

#import <Foundation/Foundation.h>
#import "Song.h"
#import "PlaybackContext.h"

@interface PreliminaryNowPlaying : NSObject
@property (nonatomic, strong) Song *aNewSong;
@property (nonatomic, strong) PlaybackContext *aNewContext;
@end
