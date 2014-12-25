//
//  SongPlayerViewDisplayUtility.h
//  Muzic
//
//  Created by Mark Zgaljic on 12/17/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SongPlayerViewDisplayUtility : NSObject

///tiny helper function for the setupVideoPlayerViewDimensionsAndShowLoading method
extern int nearestEvenInt(int to);

///6:9 Aspect ratio helper
+ (float)videoHeightInSixteenByNineAspectRatioGivenWidth:(float)width;
+ (void)segueToSongPlayerViewControllerFrom:(UIViewController *)sourceController;

@end


