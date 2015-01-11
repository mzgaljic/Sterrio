//
//  YouTubeVideoSearchService.h
//  zTunes
//
//  Created by Mark Zgaljic on 7/29/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+HTTP_Char_Escape.h"
#import "YouTubeVideoSearchDelegate.h"
#import "YouTubeVideoDurationLookupDelegate.h"
#import "YouTubeVideo.h"
#import "TBXML.h"

@interface YouTubeVideoSearchService : NSObject <NSURLConnectionDelegate>

+ (instancetype)sharedInstance;

- (void)searchYouTubeForVideosUsingString:(NSString *)searchString;
- (void)fetchNextYouTubePageUsingLastQueryString;
- (void)fetchYouTubeAutoCompleteResultsForString:(NSString *)currentString;

- (void)fetchDurationInSecondsForVideo:(YouTubeVideo *)ytVideo;

- (void)removeTheDelegate;
- (void)setTheDelegate:(id<YouTubeVideoSearchDelegate>)delegate;

- (void)setVideoDurationDelegate:(id<YouTubeVideoDurationLookupDelegate>)delegate;
- (void)removeVideoDurationDelegate;

@end
