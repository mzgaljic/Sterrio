//
//  MZConstants.m
//  Muzic
//
//  Created by Mark Zgaljic on 1/11/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZConstants.h"

@implementation MZConstants

NSString * const MZWhatsNewUserMsg = @"⌾New Features:\n•New tab bar.\n•Video player can be turned off or \"killed\" by swiping it off the screen (left direction) when it is minimized. Inspired by the YouTube app.\n•Locking the iPhone without explicitly leaving my app beforehand will no longer cause the screen to remain awake forever.\n•Default album art (from video thumbnails) are now added to new songs automatically (unless changed).\n•Dozens of smaller visual and non-visual improvements.\n\n⌾Coming Soon:\n•App color theme changes.\n•Shuffle capabilities.\n•Automatic crash reports (w/ user permission).\n•Numerous other bug fixes (the correct song will be displayed as now playing with blue text, etc.)";

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
int const MZMinVideoPlayerSwipeLengthDown = 60;
int const MZMinVideoPlayerSwipeLengthUp = 60;
int const MZMaxVideoPlayerSwipeVariance = 5;

@end
