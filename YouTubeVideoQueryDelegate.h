//
//  YouTubeVideoQueryDelegate.h
//  zTunes
//
//  Created by Mark Zgaljic on 7/30/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YouTubeVideo.h"


@protocol YouTubeVideoQueryDelegate <NSObject>

@required
/**called after the json response from the YouTube server was parsed successfully.
 The parameter youTubeVideoObjects contains an array of YouTubeVideo objects.*/
- (void)ytVideoSearchDidCompleteWithResults:(NSArray *)youTubeVideoObjects;

- (void)ytVideoNextPageResultsDidCompleteWithResults:(NSArray *)moreYouTubeVideoObjects;

- (void)ytvideoResultsNoMorePagesToView;

- (void)ytVideoAutoCompleteResultsDidDownload:(NSArray *)arrayOfYouTubeVideoSearchSuggestions;

- (void)networkErrorHasOccuredSearchingYoutube;

- (void)networkErrorHasOccuredFetchingMorePages;

@end
