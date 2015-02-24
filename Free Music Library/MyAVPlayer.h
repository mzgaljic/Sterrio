//
//  MyAVPlayer.h
//  Muzic
//
//  Created by Mark Zgaljic on 10/17/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <XCDYouTubeKit/XCDYouTubeClient.h>
#import "PlayerView.h"
#import "MRProgress.h"  //loading spinner
#import "Reachability.h"
#import "Song+Utilities.h"
#import "PreferredFontSizeUtility.h"
#import "MusicPlaybackController.h"  //for using queue, etc
#import "FetchVideoInfoOperation.h"
#import "DetermineVideoPlayableOperation.h"


@interface MyAVPlayer : AVPlayer

- (void)startPlaybackOfSong:(Song *)aSong goingForward:(BOOL)yes oldSong:(Song *)oldSong;

- (void)begingLoadingPlayerWithPlayerItem:(AVPlayerItem *)item;

- (void)showSpinnerForInternetConnectionIssue;
- (void)showSpinnerForBasicLoading;
- (void)showSpinnerForWifiNeeded;
- (void)dismissAllSpinnersIfPossible;

//should NEVER be called directly, except by the connectionStateChanged method
//or after song is done playing, or if a song is being skipped.
- (void)dismissAllSpinners;

- (void)songNeedsToBeSkippedDueToIssue;

@end
