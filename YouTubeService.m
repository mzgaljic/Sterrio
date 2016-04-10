//
//  YouTubeVideoSearchService.m
//  zTunes
//
//  Created by Mark Zgaljic on 7/29/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "YouTubeService.h"
#import "YouTubeVideo.h"
#import "SMWebRequest.h"
#import "YouTubeSearchSuggestion.h"

@interface YouTubeService ()
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
@property (nonatomic, assign) NSObject<YouTubeServiceSearchingDelegate>* queryDelegate;
@property (nonatomic, assign) id<YouTubeVideoDetailLookupDelegate> vidDurationDelegate;
@property (nonatomic, strong) NSDateFormatter *ytVideoDateFormatter;

@property (nonatomic, strong) SMWebRequest *searchTextSuggestionsRequest;
@end

@implementation YouTubeService
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

- (void)setVideoQueryDelegate:(id<YouTubeServiceSearchingDelegate>)myDelegate;
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
    if(self  = [super init]){
        //&fields=items(id,snippet(publishedAt,title,channelTitle,thumbnails))
        API_KEY = @"AIzaSyBAFK0pOUf4IWdfS94dYk_42dO46ssTUH8";
        QUERY_BASE = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/search?type=video&part=snippet&maxResults=15&fields=nextPageToken,items(id(videoId),snippet(publishedAt,title,channelTitle,thumbnails(default(url),medium(url),high(url))))&key=%@&q=", API_KEY];
        QUERY_SUGGESTION_BASE = @"http://suggestqueries.google.com/complete/search?client=youtube&ds=yt&q=";
        NEXT_PAGE_QUERY_BASE = @"&pageToken=";
        
        VIDEO_INFO_BASE = @"https://www.googleapis.com/youtube/v3/videos?id=";
        VIDEO_INFO_APPEND_ME = [NSString stringWithFormat:@"&part=contentDetails&key=%@", API_KEY];
        
        _ytVideoDateFormatter = [[NSDateFormatter alloc] init];
        //all dates from YouTube API use the UTC timezone
        [_ytVideoDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [_ytVideoDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        [_ytVideoDateFormatter setFormatterBehavior:NSDateFormatterBehaviorDefault];
    }
    return self;
}

#pragma mark - Performing a query
- (void)searchYouTubeForVideosUsingString:(NSString *)searchString
{
    if(searchString){
        NSString *queryText = [searchString stringForHTTPRequest];
        NSString *fullUrlText = [NSString stringWithFormat:@"%@%@", QUERY_BASE, queryText];
        originalQueryUrl = fullUrlText;
        __weak YouTubeService *weakSelf = self;
        
        NSURL *myUrl = [NSURL URLWithString:fullUrlText];
        NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:myUrl];
        
        //these two are required to receive a gzip response from the api (saved bandwith)
        [mutableRequest setValue:@"iOS App (gzip)" forHTTPHeaderField:@"User-Agent"];
        [mutableRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [mutableRequest setCachePolicy:NSURLRequestUseProtocolCachePolicy];
        [mutableRequest setTimeoutInterval:time_out_interval_seconds];
        
        //this queue object should not be reused. fix all this messy code in an update
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [NSURLConnection sendAsynchronousRequest:mutableRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
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
static NSOperationQueue *fetchDetailsForVideoQueue = nil;
- (void)fetchDetailsForVideo:(YouTubeVideo *)ytVideo
{
    if(ytVideo){
        __weak YouTubeVideo *weakVideo = ytVideo;
        NSMutableString *tempUrl = [NSMutableString stringWithString: VIDEO_INFO_BASE];
        [tempUrl appendString:ytVideo.videoId];
        [tempUrl appendString:VIDEO_INFO_APPEND_ME];
        NSString *videoInfoUrl = [NSString stringWithString:tempUrl];
        __weak YouTubeService *weakSelf = self;
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:videoInfoUrl]
                                                    cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                timeoutInterval:time_out_interval_seconds];
        if(fetchDetailsForVideoQueue == nil) {
            fetchDetailsForVideoQueue = [NSOperationQueue new];
            [fetchDetailsForVideoQueue setMaxConcurrentOperationCount:1];
        } else {
            [fetchDetailsForVideoQueue cancelAllOperations];
        }
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:fetchDetailsForVideoQueue
                               completionHandler:^
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
        __weak YouTubeService *weakSelf = self;
        
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
- (void)cancelAllYtAutoCompletePendingRequests
{
    [self.searchTextSuggestionsRequest removeTarget:self];
    [self.searchTextSuggestionsRequest cancel];
}

- (void)videoSuggestionsRequestComplete:(NSArray *)theItems
{
    [self.queryDelegate performSelectorOnMainThread:@selector(ytVideoAutoCompleteResultsDidDownload:)
                                         withObject:theItems
                                      waitUntilDone:NO];
}

- (void)videoSuggestionsRequestError:(NSError *)theError
{
    //delegate doesn't have method for failed suggestions, just don't do anything.
}

- (void)fetchYouTubeAutoCompleteResultsForString:(NSString *)currentString
{
    [self.searchTextSuggestionsRequest cancel]; // in case one was running already
    self.searchTextSuggestionsRequest = [YouTubeSearchSuggestion requestForYouTubeSearchSuggestions:currentString];
    [self.searchTextSuggestionsRequest addTarget:self
                                          action:@selector(videoSuggestionsRequestComplete:)
                                forRequestEvents:SMWebRequestEventComplete];
    [self.searchTextSuggestionsRequest addTarget:self
                                          action:@selector(videoSuggestionsRequestError:)
                                forRequestEvents:SMWebRequestEventError];
    [self.searchTextSuggestionsRequest start];
}


#pragma mark - Parsing query response
//returns array of YouTubeVideo objects
- (NSArray *)parseYouTubeVideoResultsResponse:(NSData *)jsonData
{
    if(jsonData == nil || jsonData.length == 0) {
        [Answers logCustomEventWithName:MZAnswersEventLogRestApiConsumptionProblemName
                       customAttributes:@{@"Rest Api Consumption Problem"
                                          : @"YT Search API V3. Data is nil or length == 0."}];
    }
    //NOTE: Not seeing a field you're expecting in the debugger? The query itself is only
    //asking for particular Obj properties in the response. Check that first if you're confused.
    
    //root dictionary
    NSDictionary *allDataDict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];

    //update nextPageToken
    nextPageToken = [allDataDict objectForKey:@"nextPageToken"];
    
    //dictionary we will iterate through (contains video results)
    NSArray *itemsArray = [allDataDict objectForKey:@"items"];
    allDataDict = nil;
    
    NSDictionary *itemDictAtIndexI;
    NSDictionary *snippetAtItemIndex;
    NSDictionary *idDictAtIndex;
    NSDictionary *thumbnailsDict;
    NSDictionary *mediumQualityThumbnailDict;
    NSDictionary *highQualityThumbnailDict;
    
    //target strings
    NSString *videoTitle;
    NSString *channelTitle;
    NSString *publishedAtText;
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
        itemDictAtIndexI = itemsArray[i];
        snippetAtItemIndex = [itemDictAtIndexI objectForKey:@"snippet"];
        idDictAtIndex = [itemDictAtIndexI objectForKey:@"id"];
        videoID = [idDictAtIndex objectForKey:@"videoId"];
        videoTitle = [snippetAtItemIndex objectForKey:@"title"];
        channelTitle = [snippetAtItemIndex objectForKey:@"channelTitle"];
        publishedAtText = [snippetAtItemIndex objectForKey:@"publishedAt"];

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
        ytVideo.publishDate = [self dateFromISO8601FormattedString:publishedAtText];
    }
    return parsedArray;
}

#pragma mark - Parsing XML response for duration
- (NSDictionary *)parseYouTubeVideoForDetails:(NSData *)JSONdata
{
    //root dictionary
    NSDictionary *allDataDict = [NSJSONSerialization JSONObjectWithData:JSONdata
                                                                options:kNilOptions
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

- (NSDate *)dateFromISO8601FormattedString:(NSString *)string
{
    return [_ytVideoDateFormatter dateFromString:string];
}

#pragma mark - Video Presence on Youtube.com
//BLOCKS the caller. Does not waste API key quota.
static NSMutableArray *videoExistsCache = nil;
static const int VIDEO_CACHE_MAX_SIZE = 15;
+ (BOOL)doesVideoStillExist:(NSString *)youtubeVideoId
{
    //cache is an array of NSDictionary object (each with only 1 key-value mapping)
    if(videoExistsCache == nil) {
        videoExistsCache = [[NSMutableArray alloc] initWithArray:@[]];
    }
    
    //check if its already in the cache to avoid hitting the internet
    for(NSDictionary *dict in videoExistsCache) {
        NSString *videoId = [[dict allKeys] lastObject];
        if([youtubeVideoId isEqualToString: videoId]) {
            return [[[dict allValues] lastObject] boolValue];
        }
    }
   
    //reduce cache size if it's reaching the limit
    if(videoExistsCache.count > 0 && videoExistsCache.count == VIDEO_CACHE_MAX_SIZE) {
        [videoExistsCache removeObjectAtIndex:videoExistsCache.count-1];
    }
    
    
    //checks the status code without actually downloading the response.  :)
    NSString *urlString = [NSString stringWithFormat:@"https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=%@&format=json", youtubeVideoId];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:3.0];
    [request setHTTPMethod:@"HEAD"];
    NSHTTPURLResponse* response = nil;
    NSError* error = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSInteger statusCode = [response statusCode];
    
    //general note: better to lie and say YES than to freak the user out by saying the video is
    //no longer available.
    BOOL retVal;
    switch (statusCode) {
        case 404:  //'Not Found'
            retVal =  NO;
            break;
        case 410:  //'Gone'
            retVal =  NO;
            break;
        default:
            retVal = YES;
            break;
    }
    [videoExistsCache addObject:@{youtubeVideoId : [NSNumber numberWithBool:retVal]}];
    return retVal;
}

@end
