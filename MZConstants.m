//
//  MZConstants.m
//  Muzic
//
//  Created by Mark Zgaljic on 1/11/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZConstants.h"

@implementation MZConstants

//backgrounding
NSString * const MZStartBackgroundTaskHandlerIfInactive = @"background handler will begin if not running";


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
NSString * const MZMainScreenVCStatusBarAlwaysVisible = @"status bar should always be visible";

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
short const MZSkipToSongBeginningIfBackBtnTappedBoundary = 3;

//Tab bar
short const MZTabBarHeight = 50;
NSString * const MZHideTabBarAnimated = @"BOOL passed in notification indicates whether or not tab bar will hide.";




NSString * const MZWhatsNewUserMsg = @"NEW STUFF\n\n•Slide a song to queue it up! (play it next)\n•The way the entire queue of songs is handled has been completely re-done from the ground up. Expect a possible bug or two.\n•An overall much more polished feel (excluding the new playback queue).\n•The classic tab bar has made a return, but now its less ugly.\n•New color scheme\n•Less clutter on the top bar.\n•Dedicated + button now on tab bar.\n•if 3+ seconds of a song have loaded, pressing the back button will start the song from the beginning (like itunes).\n•fixed very annoying issue where all songs would fail to play until app was restarted.\n•Playback queue now automatically takes into account new songs (in a playlist, the library, etc)\n\ncaution:\n\nQueuing up an entire playlist or even playlist songs seems to crash the app sometimes\n\nThe playback queue screen may crash entirely on older ios7 devices for now.";

@end
