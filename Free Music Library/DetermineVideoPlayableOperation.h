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

- (id)initWithSong:(Song *)theSong;

@end