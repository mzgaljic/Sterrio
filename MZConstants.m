//
//  MZConstants.m
//  Muzic
//
//  Created by Mark Zgaljic on 1/11/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZConstants.h"

@implementation MZConstants

NSString * const MZWhatsNewUserMsg = @"⌾New Features:\n•Vevo videos are now working again. This is a temporary fix.\n•Automatic crash reports (currently cannot be disabled. An option to disable is coming soon).•Swiping left on the minimized video player (to kill the player) is no longer glitchy. Swipe gestures have been improved on the video player as well.\n\n⌾Coming Soon:\n•App color theme changes.\n•Shuffle capabilities.\n•Numerous other bug fixes.";

//used for sending playback signals to video preview player if it exists
NSString * const MZPreviewPlayerTogglePlayPause = @"togglePlayPauseVideoPreviewPlayer";
NSString * const MZPreviewPlayerPlay = @"playVideoPreviewPlayer";
NSString * const MZPreviewPlayerPause = @"pauseVideoPreviewPlayer";
NSString * const MZAppWasBackgrounded = @"appEnteredBackgroundState";

NSString * const MZNewSongLoading = @"AVPlayer will try to load a new song now";

NSString * const MZKeyNumLikes = @"numLikes";
NSString * const MZKeyNumDislikes = @"numDislikes";
NSString * const MZKeyVideoDuration = @"videoDuration";
#warning Replace with an official email before making app production ready
NSString * const MZEmailBugReport = @"marksBetaMusicApp@gmail.com";
NSString * const MZUserCanTransitionToMainInterface = @"user can transition to main interface";
NSString * const MZUserFinishedWithReviewingSettings = @"User finished looking at Settings VC";

short const MZMinutesInAnHour = 60;
short const MZSecondsInAMinute = 60;
short const MZLongestCellularPlayableDuration = 600;

float const MZCellImageViewFadeDuration = 0.49;

//used to figuring out what a "valid" swipe up and down is on the player
int const MZMinVideoPlayerSwipeLengthDown = 60;
int const MZMinVideoPlayerSwipeLengthUp = 60;
int const MZMaxVideoPlayerSwipeVariance = 5;

@end
