//
//  PreviousNowPlayingInfo.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/23/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "PreviousNowPlayingInfo.h"
#import "PlaybackContext.h"
@interface PreviousNowPlayingInfo ()
@property (nonatomic, strong) PlayableItem *previousPlayableItem;
@end

@implementation PreviousNowPlayingInfo
static PreviousNowPlayingInfo *thisSingleton;

//--------Playable Item stuff-------
+ (PlayableItem *)playableItemBeforeNewSongBeganLoading
{
    if(thisSingleton == nil){
        thisSingleton = [PreviousNowPlayingInfo sharedInstance];
    }
    return thisSingleton.previousPlayableItem;
}

+ (void)setPreviousPlayableItem:(PlayableItem *)oldItem
{
    if(thisSingleton == nil){
        thisSingleton = [PreviousNowPlayingInfo sharedInstance];
    }
    thisSingleton.previousPlayableItem = oldItem;
}

//-----Other--------
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
