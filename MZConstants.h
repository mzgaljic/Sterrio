//
//  MZConstants.h
//  Muzic
//
//  Created by Mark Zgaljic on 1/11/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MZConstants : NSObject

extern NSString * const MZKeyNumLikes;
extern NSString * const MZKeyNumDislikes;
extern NSString * const MZKeyVideoDuration;
extern NSString * const MZEmailBugReport;

extern short const MZMinutesInAnHour;
extern short const MZSecondsInAMinute;

extern int const MZMinVideoPlayerSwipeLengthDown;
extern int const MZMinVideoPlayerSwipeLengthUp;
extern int const MZMaxVideoPlayerSwipeVariance;

@end
