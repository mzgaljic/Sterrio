//
//  KillingPlayerIntro.m
//  Sterrio
//
//  Created by Mark Zgaljic on 12/20/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import "KillingPlayerIntro.h"
#import "MZPlayer.h"

@interface KillingPlayerIntro ()
@property (nonatomic, strong) MZPlayer *player;
@end
@implementation KillingPlayerIntro

- (void)resumeVideoLooping
{
    [self.player play];
}

@end
