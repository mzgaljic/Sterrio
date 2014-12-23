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


@interface MyAVPlayer : AVPlayer

- (void)startPlaybackOfSong:(Song *)aSong goingForward:(BOOL)yes;

@end
