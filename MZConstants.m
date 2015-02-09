//
//  MZConstants.m
//  Muzic
//
//  Created by Mark Zgaljic on 1/11/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZConstants.h"

@implementation MZConstants

NSString * const MZWhatsNewUserMsg = @"⌾New Features:\n•Loading spinner! Its finally here and its gorgeous. :) I think you'll love it.\n•Loss of internet connection is detected while videos are playing back.\n\n⌾Bug Fixes:\n•Video player glitches (very erratic behavior with slider and time labels)\n•Song label animations in the video player have been improved.\n•Quick taps on minimized video player would go undetected.\n•Lockscreen and Control center would display incorrect elapsed (current) playback values, especially when skipping forwards or backwards in a song.\n•A previewed YouTube video reaching the end of its playback duration would cause any existing minimized  video players to become active again; potentially causing two songs to play at once.\n\n⌾NOW BROKEN\n•Leaving the app while previewing a video (song not yet saved) will cause it to be paused. User must manually re-enable playback using control center (swiping up from bottom of screen).\n•Loading spinner animations are glitchy when changing the players size.";

//used for sending playback signals to video preview player if it exists
NSString * const MZPreviewPlayerTogglePlayPause = @"togglePlayPauseVideoPreviewPlayer";
NSString * const MZPreviewPlayerPlay = @"playVideoPreviewPlayer";
NSString * const MZPreviewPlayerPause = @"pauseVideoPreviewPlayer";
NSString * const MZAppWasBackgrounded = @"appEnteredBackgroundState";

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
int const MZMinVideoPlayerSwipeLengthDown = 110;
int const MZMinVideoPlayerSwipeLengthUp = 82;
int const MZMaxVideoPlayerSwipeVariance = 60;

@end
