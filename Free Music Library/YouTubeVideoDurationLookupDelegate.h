//
//  YouTubeVideoDurationLookupDelegate.h
//  Muzic
//
//  Created by Mark Zgaljic on 1/11/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YouTubeVideo.h"

@protocol YouTubeVideoDurationLookupDelegate <NSObject>

- (void)ytVideoDurationHasBeenFetched:(NSUInteger)durationInSeconds forVideo:(YouTubeVideo *)video;

- (void)networkErrorHasOccuredFetchingVideoDurationForVideo:(YouTubeVideo *)video;

@end
