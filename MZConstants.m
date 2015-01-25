//
//  MZConstants.m
//  Muzic
//
//  Created by Mark Zgaljic on 1/11/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZConstants.h"

@implementation MZConstants

NSString * const MZKeyNumLikes = @"numLikes";
NSString * const MZKeyNumDislikes = @"numDislikes";
NSString * const MZKeyVideoDuration = @"videoDuration";
#warning Replace with an official email before making app production ready
NSString * const MZEmailBugReport = @"marksBetaMusicApp@gmail.com";

short const MZMinutesInAnHour = 60;
short const MZSecondsInAMinute = 60;

//used to figuring out what a "valid" swipe up and down is on the player
int const MZMinVideoPlayerSwipeLengthDown = 120;
int const MZMinVideoPlayerSwipeLengthUp = 85;
int const MZMaxVideoPlayerSwipeVariance = 60;

@end
