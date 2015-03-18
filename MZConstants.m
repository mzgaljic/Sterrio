//
//  MZConstants.m
//  Muzic
//
//  Created by Mark Zgaljic on 1/11/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZConstants.h"

@implementation MZConstants

//reachability
NSString * const MZReachabilityStateChanged = @"Reachability state change";
NSString * const MZInterfaceNeedsToBlockCurrentSongPlayback = @"pass bool as NSNumber for state.";

//used for sending playback signals to video preview player if it exists
NSString * const MZPreviewPlayerTogglePlayPause = @"togglePlayPauseVideoPreviewPlayer";
NSString * const MZPreviewPlayerPlay = @"playVideoPreviewPlayer";
NSString * const MZPreviewPlayerPause = @"pauseVideoPreviewPlayer";
NSString * const MZAppWasBackgrounded = @"appEnteredBackgroundState";
NSString * const MZNewTimeObserverCanBeAdded = @"new avplayer has been created.";

NSString * const MZPlayerToggledOnScreenStatus = @"the status has been toggled";

NSString * const MZNewSongLoading = @"AVPlayer will try to load a new song now";
NSString * const MZAVPlayerStallStateChanged = @"AVPlayer stalls changed";

NSString * const MZKeyNumLikes = @"numLikes";
NSString * const MZKeyNumDislikes = @"numDislikes";
NSString * const MZKeyVideoDuration = @"videoDuration";
#warning Replace with an official email before making app production ready
NSString * const MZEmailBugReport = @"marksBetaMusicApp@gmail.com";
NSString * const MZAddSongToUpNextString = @"Play Next";
NSString * const MZUserCanTransitionToMainInterface = @"user can transition to main interface";
NSString * const MZUserFinishedWithReviewingSettings = @"User finished looking at Settings VC";

short const MZMinutesInAnHour = 60;
short const MZSecondsInAMinute = 60;
short const MZLongestCellularPlayableDuration = 600;

float const MZCellImageViewFadeDuration = 0.49f;
float const MZSmallPlayerVideoFramePadding = 6.0f;
short const MZTabBarHeight = 50;
short const MZSkipToSongBeginningIfBackBtnTappedBoundary = 3;






NSString * const MZWhatsNewUserMsg = @"⚠️BIG CHANGES⚠️\n Sorry for the big ugly message...\n\n•Genre's are gone\n•App can now understand the concept of a song having \"context\". i.e.: it can tell whether a song was selected from the songs tab or within a specific playlist.\n•Video player itself is very robust now. Trying to play a long video (10 min+) will cause it to be skipped if on 3G, LTE, etc. Furthermore, the player can now immediately detect if a wifi connection is lost and stop all video buffering--saving data usage. Once a wifi connection is detected again, the video will continue buffering from the same exact point.\n•You can now aggresively jump between songs without lag in the interface. Furthermore, skipping a song will now stop all video buffering for that item, minimizing cellular data usage.\n•Now playing song is automatically displayed with blue text to easily identify it. Updates correctly now too.\n•Helpful messages are now embedded within the lock screen and control center during playback. Events such as buffering, loading, etc. can be communicated to the user without unlocking the device.\n•Most screens in the app can now \"make room\" for the video player when its on screen, avoiding a song being obstructed by the player.\n•Song will no longer stop loading if you leave the app mid-load.\n•Probably a hundred or so smaller fixes...";

@end
