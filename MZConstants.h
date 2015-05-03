//
//  MZConstants.h
//  Muzic
//
//  Created by Mark Zgaljic on 1/11/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MZConstants : NSObject

//backgrounding
extern NSString * const MZStartBackgroundTaskHandlerIfInactive;

//reachability
extern NSString * const MZReachabilityStateChanged;
extern NSString * const MZInterfaceNeedsToBlockCurrentSongPlayback;

//used for sending playback signals to video preview player if it exists
extern NSString * const MZPreviewPlayerTogglePlayPause;
extern NSString * const MZPreviewPlayerPlay;
extern NSString * const MZPreviewPlayerPause;
extern NSString * const MZAppWasBackgrounded;
extern NSString * const MZNewTimeObserverCanBeAdded;

extern NSString * const MZPlayerToggledOnScreenStatus;
extern NSString * const MZMainScreenVCStatusBarAlwaysInvisible;

extern NSString * const MZFileNameOfLqAlbumArtObjs;
extern NSString * const MZNewSongLoading;
extern NSString * const MZAVPlayerStallStateChanged;

extern NSString * const MZInitAudioSession;

extern NSString * const MZKeyNumLikes;
extern NSString * const MZKeyNumDislikes;
extern NSString * const MZKeyVideoDuration;
extern NSString * const MZEmailBugReport;
extern NSString * const MZAddSongToUpNextString;
extern NSString * const MZUserCanTransitionToMainInterface;
extern NSString * const MZUserFinishedWithReviewingSettings;
extern NSString * const MZUserChangedFontSize;

//icloud
extern NSString * const MZTurningOnIcloudFailed;
extern NSString * const MZTurningOffIcloudSuccess;
extern NSString * const MZTurningOffIcloudFailed;
extern NSString * const MZTurningOnIcloudSuccess;

extern short const MZMinutesInAnHour;
extern short const MZSecondsInAMinute;
extern short const MZLongestCellularPlayableDuration;

extern float const MZCellImageViewFadeDuration;
extern float const MZSmallPlayerVideoFramePadding;
extern short const MZSkipToSongBeginningIfBackBtnTappedBoundary;


//Tab bar
extern short const MZTabBarHeight;
extern NSString * const MZHideTabBarAnimated;

extern NSString * const MZWhatsNewUserMsg;

@end
