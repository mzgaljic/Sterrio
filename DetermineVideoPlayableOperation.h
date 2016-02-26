//
//  DetermineVideoPlayableOperation.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/21/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"
#import "ReachabilitySingleton.h"
#import "MusicPlaybackController.h"

@interface DetermineVideoPlayableOperation : NSOperation

- (id)initWithSongDuration:(NSUInteger)songduration youtubeVideoId:(NSString *)videoId songName:(NSString *)songName artistName:(NSString *)artistName;
- (BOOL)allowedToPlayVideo;  //access by operations dependant on this one (ie: FetchVideoInfoOperation)

@end
