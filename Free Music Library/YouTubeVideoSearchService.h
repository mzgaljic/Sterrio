//
//  YouTubeVideoSearchService.h
//  zTunes
//
//  Created by Mark Zgaljic on 7/29/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YouTubeVideoSearchDelegate.h"
#import "YouTubeVideo.h"
#import "NSString+HTTP_Char_Escape.h"

@interface YouTubeVideoSearchService : NSObject <NSURLConnectionDelegate>

- (void)searchYouTubeForVideosUsingString:(NSString *)searchString;
- (void)fetchNextYouTubePageForLastQuery;
- (void)fetchYouTubeAutoCompleteResultsForString:(NSString *)currentString;
- (void)setDelegate:(id<YouTubeVideoSearchDelegate>)delegate;
+ (void)removeDelegate;

@end
