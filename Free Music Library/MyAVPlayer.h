//
//  MyAVPlayer.h
//  Muzic
//
//  Created by Mark Zgaljic on 10/17/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <XCDYouTubeKit/XCDYouTubeClient.h>
#import "Reachability.h"
#import "Song+Utilities.h"
#import "SDCAlertView.h"  //custom alert view
#import "PreferredFontSizeUtility.h"
#import "MusicPlaybackController.h"  //for using queue, etc


NSString * const NEW_SONG_IN_AVPLAYER = @"New song added to AVPlayer, lets hope the interface makes appropriate changes.";
NSString * const AVPLAYER_DONE_PLAYING = @"Avplayer has no more items to play.";

@interface MyAVPlayer : AVPlayer

- (id)initWithURL:(NSURL *)URL;
- (void)startPlaybackOfSong:(Song *)aSong goingForward:(BOOL)yes;

@end
