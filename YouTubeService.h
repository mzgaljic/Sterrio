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

#pragma mark - Video Presence on Youtube.com
/*
 * Blocks the caller. 
 *
 * Will return NO only if the video corresponding to the given videoID is no longer available.
 * YES will be returned if the video still exists, or if the operation failed (network issue,
 * the REST endpoint was discontinued, etc.)
 */
- (BOOL)doesVideoStillExist:(NSString *)youtubeVideoId;

@end
