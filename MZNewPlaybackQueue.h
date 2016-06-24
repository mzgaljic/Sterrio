//
//  MZNewPlaybackQueue.h
//  Sterrio
//
//  Created by Mark Zgaljic on 6/23/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MZPlaybackQueueSnapshot.h"
#import "AppEnvironmentConstants.h"
@import CoreData;

@interface MZNewPlaybackQueue : NSObject

- (id)initWithNewNowPlayingPlayableItem:(PlayableItem *)item;

- (MZPlaybackQueueSnapshot *)snapshotOfPlaybackQueue;

- (PlayableItem *)seekBackOneItem;
- (PlayableItem *)seekForwardOneItem;

- (void)setShuffleState:(SHUFFLE_STATE)state;
- (void)setRepeatMode:(PLABACK_REPEAT_MODE)mode;

#pragma mark - DEBUG
- (void)printQueueContents;

@end
