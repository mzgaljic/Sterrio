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
    
    NSString *API_KEY;
    //base strings used to build url request string
    NSString *QUERY_BASE;
    NSString *QUERY_SUGGESTION_BASE;
    NSString *NEXT_PAGE_QUERY_BASE;
    
    //base strings for obtaining specific video information (XML response)
    NSString *VIDEO_INFO_BASE;
    NSString *VIDEO_INFO_APPEND_ME;
}
@property (nonatomic, assign) id<YouTubeVideoQueryDelegate> queryDelegate;
@property (nonatomic, assign) id<YouTubeVideoDetailLookupDelegate> vidDurationDelegate;
@end

@implementation YouTubeVideoSearchService
const int time_out_interval_seconds = 10;

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (void)setVideoQueryDelegate:(id<YouTubeVideoQueryDelegate>)myDelegate;
{
    self.queryDelegate = myDelegate;
}

- (void)removeVideoQueryDelegate;
{
    self.queryDelegate = nil;
}

- (void)setVideoDetailLookupDelegate:(id<YouTubeVideoDetailLookupDelegate>)myDelegate;
{
    self.vidDurationDelegate = myDelegate;
}

- (void)removeVideoDetailLookupDelegate
{
    self.vidDurationDelegate = nil;
}

- (id)init
{
    if([super init]){
        API_KEY = @"AIzaSyBAFK0pOUf4IWdfS94dYk_42dO46ssTUH8";
        QUERY_BASE = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/search?type=video&part=snippet&maxResults=15&key=%@&q=", API_KEY];
        QUERY_SUGGESTION_BASE = @"http://suggestqueries.google.com/complete/search?client=youtube&ds=yt&q=";
        NEXT_PAGE_QUERY_BASE = @"&pageToken=";
        
        VIDEO_INFO_BASE = @"https://www.googleapis.com/youtube/v3/videos?id=";
        VIDEO_INFO_APPEND_ME = [NSString stringWithFormat:@"&part=contentDetails&key=%@", API_KEY] ;
    }
    return self;
}

#pragma mark - Performing a query
- (void)searchYouTubeForVideosUsingString:(NSString *)searchString
{
    if(searchString){
        NSMutableString *tempUrl = [NSMutableString stringWithString: QUERY_BASE];
        [tempUrl appendString:[searchString stringForHTTPRequest]];
        NSString *queryUrl = [NSString stringWithString:tempUrl];
        originalQueryUrl = queryUrl;
        __weak YouTubeVideoSearchService *weakSelf = self;
        
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:queryUrl]
                                                    cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                timeoutInterval:time_out_interval_seconds];
        
        //this queue object should not be reused. fix all this messy code in an update
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
        {
            if (data == nil){
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [weakSelf.queryDelegate networkErrorHasOccuredSearchingYoutube];
                });
            } else{
                //data received...continue processing
                NSArray *parsedContent = [weakSelf parseYouTubeVideoResultsResponse:data];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [weakSelf.queryDelegate ytVideoSearchDidCompleteWithResults:parsedContent];
                });
            }
        }];
    }
}

#pragma mark - Fetching Video duration
- (void)fetchDetailsForVideo:(YouTubeVideo *)ytVideo
{
    if(ytVideo){
        __weak YouTubeVideo *weakVideo = ytVideo;
        NSMutableString *tempUrl = [NSMutableString stringWithString: VIDEO_INFO_BASE];
        [tempUrl appendString:ytVideo.videoId];
        [tempUrl appendString:VIDEO_INFO_APPEND_ME];
        NSString *videoInfoUrl = [NSString stringWithString:tempUrl];
        __weak YouTubeVideoSearchService *weakSelf = self;
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:videoInfoUrl]
                                                    cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                timeoutInterval:time_out_interval_seconds];
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        
        [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^
         (NSURLResponse *response, NSData *data, NSError *connectionError)
         {
             if (data == nil){
                 dispatch_sync(dispatch_get_main_queue(), ^{
                     [weakSelf.vidDurationDelegate networkErrorHasOccuredFetchingVideoDetailsForVideo:weakVideo];
                 });
             } else{ //data received...continue processing
                 NSDictionary *details = [weakSelf parseYouTubeVideoForDetails:data];
                 dispatch_sync(dispatch_get_main_queue(), ^{
                     [weakSelf.vidDurationDelegate detailsHaveBeenFetchedForYouTubeVideo:weakVideo
                                                                                 details:details];
                 });
             }
         }];
    } else
        return;
}

#pragma mark - Fetching more video (ie: Next Page)
- (void)fetchNextYouTubePageUsingLastQueryString
{
    if(nextPageToken == nil){ //user has gone through all available 'pages' in the result
        [self.queryDelegate ytvideoResultsNoMorePagesToView];
        return;
    }
    if(originalQueryUrl){
        NSMutableString *tempUrl = [NSMutableString stringWithString: originalQueryUrl];
        [tempUrl appendString:NEXT_PAGE_QUERY_BASE];
        [tempUrl appendString:nextPageToken];
        NSString *queryUrl = [NSString stringWithString:tempUrl];
        __weak YouTubeVideoSearchService *weakSelf = self;
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:queryUrl]
                                                 cachePolicy:NSURLRequestUseProtocolCachePolicy
                                             timeoutInterval:time_out_interval_seconds];
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        
        [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^
            (NSURLResponse *response, NSData *data, NSError *connectionError)
        {
            if (data == nil){
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [weakSelf.queryDelegate networkErrorHasOccuredFetchingMorePages];
                });
            } else{
                // Data received...continue processing
                NSArray *parsedContent = [weakSelf parseYouTubeVideoResultsResponse:data];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [weakSelf.queryDelegate ytVideoNextPageResultsDidCompleteWithResults:parsedContent];
                });
            }
        }];
    } else
        return;
}

#pragma mark - Query Auto-complete as you type
- (void)fetchYouTubeAutoCompleteResultsForString:(NSString *)currentString
{
    if(currentString){
        NSMutableString *tempUrl = [NSMutableString stringWithString: QUERY_SUGGESTION_BASE];
        [tempUrl appendString:[currentString stringForHTTPRequest]];
        NSString *fullUrl = [NSString stringWithString:tempUrl];
        __weak YouTubeVideoSearchService *weakSelf = self;
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:fullUrl]
                                                 cachePolicy:NSURLRequestUseProtocolCachePolicy
                                             timeoutInterval:time_out_interval_seconds];
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        
        [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^
            (NSURLResponse *response, NSData *data, NSError *connectionError)
        {
            if (data == nil)
            {
                //don't need to display error to user, not critical to see autosuggestions.
            } else{
                // Data received...continue processing
                NSArray *parsedContent = [self parseYouTubeVideoAutoSuggestResponse:data];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [weakSelf.queryDelegate ytVideoAutoCompleteResultsDidDownload:parsedContent];
                });
            }
        }];
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

#pragma mark - Parsing XML response for duration
- (NSDictionary *)parseYouTubeVideoForDetails:(NSData *)JSONdata
{
    //root dictionary
    NSDictionary *allDataDict = [NSJSONSerialization JSONObjectWithData:JSONdata
                                                                options:NSJSONReadingMutableContainers
                                                                  error:nil];
    NSArray *itemsArray = [allDataDict objectForKey:@"items"];
    
    NSString *durationInISO8601;
    if(itemsArray.count > 0){
        NSDictionary *itemAtIndex0 = itemsArray[0];
        NSDictionary *contentDetails = [itemAtIndex0 objectForKey:@"contentDetails"];
        durationInISO8601 = [contentDetails objectForKey:@"duration"];
    }
    
    NSDictionary *details;
    if(durationInISO8601 != nil)
    {
        NSUInteger duration = [self durationFromISO8601FormattedString:durationInISO8601];
        NSNumber *durationNumObj = [NSNumber numberWithInteger:duration];
        details = @{
                    MZKeyVideoDuration    :   durationNumObj
                    };
    }

    return details;
    
    //-----old XML parsing code-----
    /*
    NSError *error;
    TBXML *tbxml = [TBXML tbxmlWithXMLData:XMLdata error:&error];
    
    if (error) {
        //dont care what error is, just return so that the app doesnt crash
        return nil;
    } else {

        TBXMLElement *root = tbxml.rootXMLElement;
        
        //getting duration
        TBXMLElement *mediaGroup = [TBXML childElementNamed:@"media:group"
                                              parentElement:root];
        TBXMLElement *mediaContent = [TBXML childElementNamed:@"media:content"
                                                parentElement:mediaGroup];
        NSString *durationText = [TBXML valueOfAttributeNamed:@"duration"
                                                   forElement:mediaContent];
        
        //getting view count
        TBXMLElement *stats = [TBXML childElementNamed:@"yt:statistics"
                                              parentElement:root];
        NSString *viewCountText = [TBXML valueOfAttributeNamed:@"viewCount"
                                                   forElement:stats];
//#warning extracted video view count...do something with this lol.
        return details;
    }
     */
}

//Accepts a string (duration) from the youtube api in ISO 8601 format duration
- (NSUInteger)durationFromISO8601FormattedString:(NSString *)string
{
    const char *stringToParse = [string UTF8String];
    int days = 0, hours = 0, minutes = 0, seconds = 0;
    
    const char *ptr = stringToParse;
    while(*ptr)
    {
        if(*ptr == 'P' || *ptr == 'T')
        {
            ptr++;
            continue;
        }
        
        int value, charsRead;
        char type;
        if(sscanf(ptr, "%d%c%n", &value, &type, &charsRead) != 2)
            ;  // handle parse error
        if(type == 'D')
            days = value;
        else if(type == 'H')
            hours = value;
        else if(type == 'M')
            minutes = value;
        else if(type == 'S')
            seconds = value;
        else
            ;  // handle invalid type
        
        ptr += charsRead;
    }
    
    NSTimeInterval interval = ((days * 24 + hours) * 60 + minutes) * 60 + seconds;
    return (NSUInteger)interval;
}

/*
 possibly useful at some point to test if videos exist anymore:
 https://www.googleapis.com/youtube/v3/videos?id=mVp0brA3Hpk&part=contentDetails&key=AIzaSyAhZM3ZPcVq4q7ZdO7Pm44_7Q6U2udxzYo
 */

@end
