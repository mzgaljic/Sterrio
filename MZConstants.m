//
//  MZConstants.m
//  Muzic
//
//  Created by Mark Zgaljic on 1/11/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZConstants.h"

@implementation MZConstants

NSString * const MZWhatsNewUserMsg = @"Improvements\n-Song and artist/album text positioning (inside song player) has been improved (especially old devices).\n\nFixed Bugs\n-Songs from the Songs tab queue up correctly now.\n-Deleting a playlist containing the now playing song used to crash the app. Not anymore.\n-Deleting the last song in the playback queue no longer results in strange behavior when opening up the player screen.";

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

short const MZMinutesInAnHour = 60;
short const MZSecondsInAMinute = 60;
short const MZLongestCellularPlayableDuration = 600;

//used to figuring out what a "valid" swipe up and down is on the player
int const MZMinVideoPlayerSwipeLengthDown = 120;
int const MZMinVideoPlayerSwipeLengthUp = 85;
int const MZMaxVideoPlayerSwipeVariance = 60;


@end
