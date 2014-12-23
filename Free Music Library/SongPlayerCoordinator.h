//
//  SongPlayerCoordinator.h
//  Muzic
//
//  Created by Mark Zgaljic on 12/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MusicPlaybackController.h"
#import "VideoPlayerControlInterfaceDelegate.h"

@interface SongPlayerCoordinator : NSObject
@property (nonatomic, weak) id<VideoPlayerControlInterfaceDelegate>delegate;
+ (instancetype)sharedInstance;

- (void)setDelegate:(id<VideoPlayerControlInterfaceDelegate>)theDelegate;
- (void)setupKeyvalueObservers;
- (void)beginShrinkingVideoPlayer;

@end
