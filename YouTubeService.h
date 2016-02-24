//
//  YouTubeVideoSearchService.h
//  zTunes
//
//  Created by Mark Zgaljic on 7/29/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+HTTP_Char_Escape.h"
#import "YouTubeVideoQueryDelegate.h"
#import "YouTubeVideoDetailLookupDelegate.h"
#import "YouTubeVideo.h"
#import "TBXML.h"

@interface YouTubeService : NSObject <NSURLConnectionDelegate>

+ (instancetype)sharedInstance;

#pragma mark - Video Queries
- (void)searchYouTubeForVideosUsingString:(NSString *)searchString;
- (void)fetchNextYouTubePageUsingLastQueryString;

- (void)cancelAllYtAutoCompletePendingRequests;
- (void)fetchYouTubeAutoCompleteResultsForString:(NSString *)currentString;

- (void)setVideoQueryDelegate:(id<YouTubeServiceSearchingDelegate>)delegate;
- (void)removeVideoQueryDelegate;


#pragma mark - Video Details
- (void)fetchDetailsForVideo:(YouTubeVideo *)ytVideo;

- (void)setVideoDetailLookupDelegate:(id<YouTubeVideoDetailLookupDelegate>)delegate;
- (void)removeVideoDetailLookupDelegate;

@end
