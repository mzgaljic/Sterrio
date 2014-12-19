//
//  SongPlayerViewDisplayHelper.h
//  Muzic
//
//  Created by Mark Zgaljic on 12/17/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString * const NEW_SONG_IN_AVPLAYER = @"New song added to AVPlayer, lets hope the interface makes appropriate changes.";
NSString * const AVPLAYER_DONE_PLAYING = @"Avplayer has no more items to play.";

@interface SongPlayerViewDisplayHelper : NSObject

///tiny helper function for the setupVideoPlayerViewDimensionsAndShowLoading method
int nearestEvenInt(int to);

///6:9 Aspect ratio helper
+ (float)videoHeightInSixteenByNineAspectRatioGivenWidth:(float)width;

@end

@implementation SongPlayerViewDisplayHelper

int nearestEvenInt(int to)
{
    return (to % 2 == 0) ? to : (to + 1);
}

+ (float)videoHeightInSixteenByNineAspectRatioGivenWidth:(float)width
{
    float tempVar = width;
    tempVar = ceil(width * 9.0f);
    return ceil(tempVar / 16.0f);
}

@end
