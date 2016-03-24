//
//  YouTubeSearchSuggestion.m
//  Sterrio
//
//  Created by Mark Zgaljic on 2/7/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "YouTubeSearchSuggestion.h"
#import "NSString+HTTP_Char_Escape.h"
#import "NSString+WhiteSpace_Utility.h"

@implementation YouTubeSearchSuggestion

+ (SMWebRequest *)requestForYouTubeSearchSuggestions:(NSString *)query
{
    // Set ourself as the background processing delegate. The caller can still add herself as a listener for the resulting data.
    NSString *urlString = @"http://suggestqueries.google.com/complete/search?client=youtube&ds=yt&q=";
    query = [query stringForHTTPRequest];
    NSURL *myUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", urlString, query]];
    NSMutableURLRequest *mutUrlRequest = [NSMutableURLRequest requestWithURL:myUrl];
    [mutUrlRequest setCachePolicy:NSURLRequestUseProtocolCachePolicy];
    
    return [SMWebRequest requestWithURLRequest:mutUrlRequest
                                      delegate:(id<SMWebRequestDelegate>)self
                                       context:nil];
}

// This method is called on a background thread. Don't touch your instance members!
+ (id)webRequest:(SMWebRequest *)webRequest resultObjectForData:(NSData *)jsonData context:(id)context
{
    // We do this gnarly parsing on a background thread to keep the UI responsive.
    if(jsonData == nil || jsonData.length == 0) {
        [Answers logCustomEventWithName:MZAnswersEventLogRestApiConsumptionProblemName
                       customAttributes:@{@"Rest Api Consumption Problem"
                                          : @"YT Search Suggestions. Data is nil or length == 0."}];
        return @[];
    }
    //content-type of response is NSISOLatin1StringEncoding
    NSMutableString *originalData = [[NSMutableString alloc] initWithData:jsonData
                                                                 encoding:NSISOLatin1StringEncoding];
    
    if(originalData.length > 0){
        //delete last character
        [originalData deleteCharactersInRange:NSMakeRange([originalData length]-1, 1)];
        
        //delete first 19 characters - "window.google.ac.h("
        if([[originalData substringToIndex:19] isEqualToString:@"window.google.ac.h("])
            [originalData deleteCharactersInRange:NSMakeRange(0, 19)];
        else{
            //response from server has changed or an error occured.
            CLS_LOG(@"%@", @"Google suggestions api response has changed! Parsing 'window.google.ac.h(' is not working properly");
            [Answers logCustomEventWithName:MZAnswersEventLogRestApiConsumptionProblemName
                           customAttributes:@{@"Rest Api Consumption Problem"
                                              : @"YT Search Suggestions. Parsing 'window.google.ac.h(' is not working properly"}];
            return @[];
        }
    }
    //root dictionary
    if(originalData == nil)
        return nil;
    
    //converting data to NSUTF8StringEncoding so that it can be easily worked with in my app.
    NSData *utf8EncodedData = [originalData dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *allDataArray = [NSJSONSerialization JSONObjectWithData:utf8EncodedData
                                                            options:kNilOptions error:nil];
    if(allDataArray == nil)
        return nil;
    
    NSArray *suggestionsArray = [allDataArray objectAtIndex:1];
    NSMutableArray *parsedArray = [NSMutableArray arrayWithCapacity:suggestionsArray.count + 1];
    [parsedArray addObject:[allDataArray objectAtIndex:0]];  //add the query text itself in front.
    allDataArray = nil;
    originalData = nil;
    
    NSArray *temp;
    for(int i = 0; i < suggestionsArray.count; i++){  //parse json response, extract suggestions.
        temp = suggestionsArray[i];
        NSString *suggestion = temp[0];
        [parsedArray addObject:suggestion];
    }
    return parsedArray;
}

@end
