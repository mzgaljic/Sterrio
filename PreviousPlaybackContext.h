//
//  PreviousPlaybackContext.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/23/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PreviousPlaybackContext : NSObject

+ (PlaybackContext *)contextBeforeNewSongBeganLoading;
+ (void)setPreviousPlaybackContext:(PlaybackContext *)oldContext;

@end
