//
//  YouTubeVideoSearchService.m
//  zTunes
//
//  Created by Mark Zgaljic on 7/29/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "YouTubeVideoSearchService.h"
#import "YouTubeVideo.h"

@interface YouTubeVideoSearchService ()
{
    NSString *nextPageToken; //set and reset when appropriate
    NSString *originalQueryUrl;
    
    //base strings used to build url request string
    NSString *QUERY_BASE;
    NSString *QUERY_SUGGESTION_BASE;
    NSString *NEXT_PAGE_QUERY_BASE;
}
@property (nonatomic, assign) id<YouTubeVideoSearchDelegate> delegate;
@end

@implementation YouTubeVideoSearchService

-(void)setTheDelegate:(id<YouTubeVideoSearchDelegate>)myDelegate
{
    self.delegate = myDelegate;
}

- (id)init
{
    if([super init]){
        QUERY_BASE = @"https://www.googleapis.com/youtube/v3/search?type=video&part=snippet&maxResults=15&key=AIzaSyBAFK0pOUf4IWdfS94dYk_42dO46ssTUH8&q=";
        QUERY_SUGGESTION_BASE = @"http://suggestqueries.google.com/complete/search?client=youtube&ds=yt&q=";
        NEXT_PAGE_QUERY_BASE = @"&pageToken=";
    }
    return self;
}

#pragma mark - Performing a query
- (void)searchYouTubeForVideosUsingString:(NSString *)searchString
{
    if(searchString){
        NSMutableString *queryUrl = [NSMutableString stringWithString: QUERY_BASE];
        [queryUrl appendString:[searchString stringForHTTPRequest]];
        originalQueryUrl = queryUrl;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            //sending a basic synchronous request here since we're off the main thread anyway
            NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:queryUrl]];
            NSURLResponse *urlResponse = nil;
            NSError *requestError = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest
                                                 returningResponse:&urlResponse error:&requestError];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                //data is nil if a connection could not be created or if the download failed.
                if (data == nil){
                    //do not need to check error type, the user doesn't care. Just notify self.delegate.
                    [self.delegate networkErrorHasOccuredSearchingYoutube];
                } else{ //data received...continue processing
                    [self.delegate ytVideoSearchDidCompleteWithResults:[self parseYouTubeVideoResultsResponse:data]];
                }
                
            }); //end of async dispatch
        });
    } else
        return; //nothing to search for
}

#pragma mark - Fetching Video duration
- (void)fetchDurationInSecondsForVideo:(YouTubeVideo *)ytVideo
{
#warning no implementation
}

#pragma mark - Fetching more video (ie: Next Page)
- (void)fetchNextYouTubePageUsingLastQueryString
{
    if(nextPageToken == nil){ //user has gone through all available 'pages' in the result
        [self.delegate ytvideoResultsNoMorePagesToView];
        return;
    }
    if(originalQueryUrl){
        NSMutableString *queryUrl = [NSMutableString stringWithString: originalQueryUrl];
        [queryUrl appendString:NEXT_PAGE_QUERY_BASE];
        [queryUrl appendString:nextPageToken];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            // Send a synchronous request here, already on a different thread
            NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:queryUrl]];
            NSURLResponse *urlResponse = nil;
            NSError *requestError = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&urlResponse error:&requestError];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (data == nil){
                    [self.delegate networkErrorHasOccuredFetchingMorePages];
                } else{  // Data received...continue processing
                    [self.delegate ytVideoNextPageResultsDidCompleteWithResults:[self parseYouTubeVideoResultsResponse:data]];
                }
            });  //end of async dispatch
        });
    }
}

#pragma mark - Query Auto-complete as you type
- (void)fetchYouTubeAutoCompleteResultsForString:(NSString *)currentString
{
    if(currentString){
        NSMutableString *fullUrl = [NSMutableString stringWithString: QUERY_SUGGESTION_BASE];
        [fullUrl appendString:[currentString stringForHTTPRequest]];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            // Send a synchronous request here, already on a different thread
            NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:fullUrl]];
            NSURLResponse *urlResponse = nil;
            NSError *requestError = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&urlResponse error:&requestError];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (data == nil){}  //don't need to display error to user, not critical to see autosuggestions.

                else{
                    // Data received...continue processing
                    [self.delegate ytVideoAutoCompleteResultsDidDownload:[self parseYouTubeVideoAutoSuggestResponse:data]];
                }
            });  //end of async dispatch
        });
    } else
        return;
}


#pragma mark - Parsing query response
//returns array of YouTubeVideo objects
- (NSArray *)parseYouTubeVideoResultsResponse:(NSData *)jsonData
{
    //root dictionary
    NSDictionary *allDataDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    //update nextPageToken
    nextPageToken = [allDataDict objectForKey:@"nextPageToken"];
    
    //dictionary we will iterate through (contains video results)
    NSArray *itemsArray = [allDataDict objectForKey:@"items"];
    allDataDict = nil;
    
    NSDictionary *itemAtIndexI;
    NSDictionary *snippetAtItemIndex;
    NSDictionary *idDictAtIndex;
    NSDictionary *thumbnailsDict;
    NSDictionary *mediumQualityThumbnailDict;
    NSDictionary *highQualityThumbnailDict;
    
    //target strings
    NSString *videoTitle;
    NSString *channelTitle;
    NSString *mediumQualityThumbnailUrl;
    NSString *highQualityThumbnailUrl;
    NSString *videoID;
    
    //reusable YouTubeVideo object var
    YouTubeVideo *ytVideo;
    
    //create array of YouTubeVideo objects to be returned. Initialize them now too.
    NSMutableArray *parsedArray = [NSMutableArray arrayWithCapacity:[itemsArray count]];
    for(int i = 0; i < itemsArray.count; i++)
        [parsedArray addObject:[[YouTubeVideo alloc] init]];
    
    for(int i = 0; i < itemsArray.count; i++){  //parse json response, extract target strings for each video result.
        itemAtIndexI = itemsArray[i];
        snippetAtItemIndex = [itemAtIndexI objectForKey:@"snippet"];
        idDictAtIndex = [itemAtIndexI objectForKey:@"id"];
        videoID = [idDictAtIndex objectForKey:@"videoId"];
        videoTitle = [snippetAtItemIndex objectForKey:@"title"];
        channelTitle = [snippetAtItemIndex objectForKey:@"channelTitle"];

        thumbnailsDict = [snippetAtItemIndex objectForKey:@"thumbnails"];
        mediumQualityThumbnailDict = [thumbnailsDict objectForKey:@"medium"];
        mediumQualityThumbnailUrl = [mediumQualityThumbnailDict objectForKey:@"url"];
        
        highQualityThumbnailDict = [thumbnailsDict objectForKey:@"high"];
        highQualityThumbnailUrl = [highQualityThumbnailDict objectForKey:@"url"];
        
        
        ytVideo = parsedArray[i];
        ytVideo.videoName = videoTitle;
        ytVideo.videoId = videoID;
        ytVideo.videoThumbnailUrl = mediumQualityThumbnailUrl;
        ytVideo.videoThumbnailUrlHighQuality = highQualityThumbnailUrl;
        ytVideo.channelTitle = channelTitle;
    }
    return parsedArray;
}

#pragma mark - Parsing Auto-completion response
//returns array of NSString objects
- (NSArray *)parseYouTubeVideoAutoSuggestResponse:(NSData *)jsonData
{
    NSMutableString *originalData = [[NSMutableString alloc] initWithData:jsonData encoding:NSNonLossyASCIIStringEncoding];
    if(originalData.length > 0){
        //delete last character
        [originalData deleteCharactersInRange:NSMakeRange([originalData length]-1, 1)];
        
        //delete first 19 characters - "window.google.ac.h("
        if([[originalData substringToIndex:19] isEqualToString:@"window.google.ac.h("])
            [originalData deleteCharactersInRange:NSMakeRange(0, 19)];
        else
            //response from server has changed or an error occured.
            return nil;
    }
    //root dictionary
    if(originalData == nil)
        return nil;
    NSArray *allDataArray = [NSJSONSerialization JSONObjectWithData:[originalData dataUsingEncoding:NSNonLossyASCIIStringEncoding]
                                                                options:NSJSONReadingMutableContainers error:nil];
    if(allDataArray == nil)
        return nil;
    
    NSArray *suggestionsArray = [allDataArray objectAtIndex:1];
    allDataArray = nil;
    originalData = nil;
    
    NSMutableArray *parsedArray = [NSMutableArray arrayWithCapacity:suggestionsArray.count];
    NSArray *reusableArray;
    for(int i = 0; i < suggestionsArray.count; i++){  //parse json response, extract suggestions.
        reusableArray = suggestionsArray[i];
        [parsedArray addObject: reusableArray[0]];
    }
    return parsedArray;
}

@end
