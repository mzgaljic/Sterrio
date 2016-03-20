//
//  VideoPlayerWrapper.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/16/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//
//This class wraps some common functionality around the MyAvPlayer class,
//allowing this class to re-create the AVPlayer object when it sees fit,
//without other classes being affected by this change.

#import <Foundation/Foundation.h>
#import "MyAVPlayer.h"
#import "UIWindow+VisibleVC.h"
#import "SongPlayerViewController.h"

@interface VideoPlayerWrapper : NSObject

+ (void)startPlaybackOfSong:(Song *)aSong
               goingForward:(BOOL)forward
            oldPlayableItem:(PlayableItem *)oldItem;

+ (void)beginPlaybackWithPlayerItem:(AVPlayerItem *)item;

@end
