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
NSString * const MZMainScreenVCStatusBarAlwaysInvisible = @"status bar should always be invisible";

NSString * const MZFileNameOfLqAlbumArtObjs = @"Pending Album Art Updates.txt";
NSString * const MZNewSongLoading = @"AVPlayer will try to load a new song now";
NSString * const MZAVPlayerStallStateChanged = @"AVPlayer stalls changed";

NSString * const MZInitAudioSession = @"Init the audio session if it isnt already setup";

NSString * const MZAppIntroComplete = @"Intro on initial app launch has been completed";

NSString * const MZKeyNumLikes = @"numLikes";
NSString * const MZKeyNumDislikes = @"numDislikes";
NSString * const MZKeyVideoDuration = @"videoDuration";

#warning Replace with an official email before making app production ready
NSString * const MZEmailBugReport = @"marksBetaMusicApp@gmail.com";
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

short const MZMinutesInAnHour = 60;
short const MZSecondsInAMinute = 60;
short const MZLongestCellularPlayableDuration = 600;

float const MZCellImageViewFadeDuration = 0.49f;
float const MZSmallPlayerVideoFramePadding = 6.0f;
short const MZSkipToSongBeginningIfBackBtnTappedBoundary = 3;

//Tab bar
short const MZTabBarHeight = 50;
NSString * const MZHideTabBarAnimated = @"Pass @YES in notif to hide tab bar";

//determined this would work well with smallest font size on largest iphone (iphone 6 plus)
int MZDefaultCoreDataFetchBatchSize = 35;

NSString * const MZWhatsNewUserMsg = @"Sterrio can now guess the song info for most YouTube videos (w/ a reasonably clean title.) \n\nManually entering information is now a rare occurence.";
NSString * const MZAppName = @"Sterrio";

@end
