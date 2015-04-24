//
//  PreviousPlaybackContext.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/23/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "PreviousPlaybackContext.h"
#import "PlaybackContext.h"
@interface PreviousPlaybackContext ()
@property (nonatomic, strong) PlaybackContext *previousPlaybackContext;
@end

@implementation PreviousPlaybackContext
static PreviousPlaybackContext *thisSingleton;

+ (PlaybackContext *)contextBeforeNewSongBeganLoading
{
    if(thisSingleton == nil){
        thisSingleton = [PreviousPlaybackContext sharedInstance];
    }
    
    return thisSingleton.previousPlaybackContext;
}

+ (void)setPreviousPlaybackContext:(PlaybackContext *)oldContext
{
    if(thisSingleton == nil){
        thisSingleton = [PreviousPlaybackContext sharedInstance];
    }
    
    thisSingleton.previousPlaybackContext = oldContext;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

@end
