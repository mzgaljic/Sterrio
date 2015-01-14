//
//  YouTubeVideoDetailLookupDelegate.h
//  Muzic
//
//  Created by Mark Zgaljic on 1/11/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YouTubeVideo.h"

@protocol YouTubeVideoDetailLookupDelegate <NSObject>

#pragma mark - Video Duration
- (void)detailsHaveBeenFetchedForYouTubeVideo:(YouTubeVideo *)video details:(NSDictionary *)dict;
- (void)networkErrorHasOccuredFetchingVideoDetailsForVideo:(YouTubeVideo *)video;

@end
