//
//  MZConstants.h
//  Muzic
//
//  Created by Mark Zgaljic on 1/11/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MZConstants : NSObject

//used for sending playback signals to video preview player if it exists
extern NSString * const MZPreviewPlayerTogglePlayPause;
extern NSString * const MZPreviewPlayerPlay;
extern NSString * const MZPreviewPlayerPause;

extern NSString * const MZKeyNumLikes;
extern NSString * const MZKeyNumDislikes;
extern NSString * const MZKeyVideoDuration;
extern NSString * const MZEmailBugReport;
extern NSString * const MZUserCanTransitionToMainInterface;

extern short const MZMinutesInAnHour;
extern short const MZSecondsInAMinute;
extern short const MZLongestCellularPlayableDuration;

extern int const MZMinVideoPlayerSwipeLengthDown;
extern int const MZMinVideoPlayerSwipeLengthUp;
extern int const MZMaxVideoPlayerSwipeVariance;

@end
