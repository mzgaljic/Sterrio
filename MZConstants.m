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

NSString * const MZPlayerToggledOnScreenStatus = @"the status has been toggled";
NSString * const MZMainScreenVCStatusBarAlwaysInvisible = @"status bar should always be invisible";

NSString * const MZFileNameOfLqAlbumArtObjs = @"Pending Album Art Updates.txt";
NSString * const MZNewSongLoading = @"AVPlayer will try to load a new song now";
NSString * const MZAVPlayerStallStateChanged = @"AVPlayer stalls changed";

NSString * const MZAnswersEventLogRestApiConsumptionProblemName = @"an api is not being consumed correctly anymore.";

NSString * const MZInitAudioSession = @"Init the audio session if it isnt already setup";

NSString * const MZAppIntroComplete = @"Intro on initial app launch has been completed";
NSString * const MZHideAppRatingCell = @"Can now hide the app rating cell";

NSString * const MZKeyNumLikes = @"numLikes";
NSString * const MZKeyNumDislikes = @"numDislikes";
NSString * const MZKeyVideoDuration = @"videoDuration";

NSString * const MZAdMobUnitId = @"ca-app-pub-3961646861945951/6727549027";

NSString * const MZEmailBugReport = @"bug-report@sterrio.com";
NSString * const MZEmailFeedback = @"feedback@sterrio.com";
NSString * const MZAppTermsPdfLink = @"https://dl.dropbox.com/s/3x5house6be4et4/Fabric%20TOS.pdf?dl=0";
NSString * const MZAddSongToUpNextString = @"Play Next";
NSString * const MZUserCanTransitionToMainInterface = @"user can transition to main interface";
NSString * const MZUserAboutToDismissFromSettings = @"User going to dismiss Settings VC";
NSString * const MZUserFinishedWithReviewingSettings = @"User finished looking at Settings VC";
NSString * const MZUserChangedFontSize = @"Font size has just been changed in settings";

//icloud (note the constants that trigger identical actions via notifications have identical string values
NSString * const MZTurningOnIcloudFailed = @"icloud is off";
NSString * const MZTurningOffIcloudSuccess = @"icloud is off";
NSString * const MZTurningOffIcloudFailed = @"icloud is on";
NSString * const MZTurningOnIcloudSuccess = @"icloud is on";
NSString * const MZIcloudSyncStateHasChanged = @"icloud state of app has changed";


short const MZMinutesInAnHour = 60;
short const MZSecondsInAMinute = 60;
short const MZLongestCellularPlayableDuration = 600;

float const MZCellImageViewFadeDuration = 0.49f;
int const MZCellSpotifyStylePaddingValue = 34;
float const MZSmallPlayerVideoFramePadding = 6.0f;
short const MZSkipToSongBeginningIfBackBtnTappedBoundary = 3;

//GUI Constants
short const MZTabBarHeight = 50;
float const MZLargeSpinnerDownScaleAmount = 0.85f;

//Tab bar
NSString * const MZHideTabBarAnimated = @"Pass @YES in notif to hide tab bar";

//determined this would work well with smallest font size on largest iphone (iphone 6 plus)
int MZDefaultCoreDataFetchBatchSize = 35;

NSString * const MZAppName = @"Sterrio";
int MZCurrentTosVersion = 1;  //The Terms of Service version for this build.

@end
