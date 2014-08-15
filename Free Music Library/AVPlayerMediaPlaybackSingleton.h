//
//  AVPlayerMediaPlaybackSingleton.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/9/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AVPlayerMediaPlaybackSingleton : NSObject

#pragma mark - Controling playback
/** Playback will be resumed immediately */
- (void)ResumePlayback;

/** Playback will be paused immediately */
- (void)PausePlayback;

/** Playback will continue from the specified seek point, skipping a portion of the track. */
- (void)SeekToTime;

/** Stop playback of current song/track, and begin playback of the next track */
- (void)SkipToNextTrack;

/** Stop playback of current song/track, and begin playback of previous track */
- (void)ReturnToPreviousTrack;

/** Current elapsed playback time (for the current song/track). */
- (void)CurrentTime;

@end
