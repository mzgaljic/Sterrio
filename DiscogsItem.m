//
//  DiscogsItem.m
//  FMV - Free Music Videos
//
//  Created by Mark Zgaljic on 12/27/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import "DiscogsItem.h"
#import "NSString+HTTP_Char_Escape.h"
#import "NSString+WhiteSpace_Utility.h"

@implementation DiscogsItem

#pragma mark - Public API
- (instancetype)init
{
    if(self = [super init]) {
        _matchConfidence = MatchConfidence_UNDEFINED;
    }
    return self;
}

+ (SMWebRequest *)requestForDiscogsItems:(NSString *)query;
{
    // Set ourself as the background processing delegate. The caller can still add herself as a listener for the resulting data.
    NSString *urlString = @"https://api.discogs.com/database/search?type=master&type=album&per_page=8&page=1&q=";
    query = [query stringForHTTPRequest];
    NSURL *myUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", urlString, query]];
    NSMutableURLRequest *mutUrlRequest = [NSMutableURLRequest requestWithURL:myUrl];
    [mutUrlRequest setValue:[NSString stringWithFormat:@"%@ - iOS App", MZAppName]
         forHTTPHeaderField:@"User-Agent"];
    [mutUrlRequest setValue:@"Discogs token=CHSGmUCKHjNIOeAKgbuaBZUEldBInAopLpRJiGMc"
         forHTTPHeaderField:@"Authorization"];
    [mutUrlRequest setCachePolicy:NSURLRequestUseProtocolCachePolicy];
    
    
    return [SMWebRequest requestWithURLRequest:mutUrlRequest
                                      delegate:(id<SMWebRequestDelegate>)self
                                       context:nil];
}

// This method is called on a background thread. Don't touch your instance members!
+ (id)webRequest:(SMWebRequest *)webRequest resultObjectForData:(NSData *)data context:(id)context
{
    // We do this gnarly parsing on a background thread to keep the UI responsive.
    NSDictionary *allDataDict = [NSJSONSerialization JSONObjectWithData:data
                                                                options:kNilOptions
                                                                  error:nil];
    NSArray *resultsArray = [allDataDict objectForKey:@"results"];
    NSMutableArray *itemsArray = [NSMutableArray arrayWithCapacity:allDataDict.count];
    for(NSUInteger i = 0; i < resultsArray.count; i++) {
        int year = [[resultsArray[i] objectForKey:@"year"] intValue];
        NSString *resultTitle = [resultsArray[i] objectForKey:@"title"];
        
        //space around "-" in seperator is important. Considers the fact that some artists may
        //have a "-" in their name (ie: Jay-Z). Notice how the name has a - but no space around it.
        //This is the case 99.99% of the time since Discogs has proper grammer in their titles.
        NSArray *split = [resultTitle componentsSeparatedByString:@" - "];
        NSString *albumName = nil, *artistName = nil;
        
        artistName = (split.count > 0) ? split[0] : nil;
        NSMutableString *albumNameBuilder = [NSMutableString new];
        for(int i = 1; i < split.count; i++) {
            [albumNameBuilder appendString:split[i]];
        }
        albumName = albumNameBuilder;
        
        artistName = [DiscogsItem removeRandomAsteriskAtEndOfNamesIfPresent:artistName];
        albumName = [DiscogsItem removeRandomAsteriskAtEndOfNamesIfPresent:albumName];
        artistName = [DiscogsItem removeNumberedSuffixIndicatingDupArtistOrAlbumInDiscogs:artistName];
        albumName = [DiscogsItem removeNumberedSuffixIndicatingDupArtistOrAlbumInDiscogs:albumName];
        
        NSArray *featArtists = [DiscogsItem parseFeatArtists:artistName];
        
        //looks for "ft." and removes everything starting from there to the end of the string.
        //pattern: (\(|\[|\{|\s)(ft\..+|feat\..+)
        artistName = [MZCommons deleteCharsMatchingRegex:MZRegexMatchFeatAndFtToEndOfString
                                             usingString:artistName];
        
        //the DiscogsItem songName is set in YouTubeSongAdderViewController when results are processed.
        DiscogsItem *item = [[DiscogsItem alloc] init];
        item.featuredArtists = featArtists;
        item.artistName = artistName;
        item.albumName = albumName;
        item.releaseYear = year;
        item.formats = [resultsArray[i] objectForKey:@"format"];
        [itemsArray addObject:item];
    }
    return itemsArray;
}

- (BOOL)isAlbumVinylCDOrEP
{
    NSArray *formats = self.formats;    
    if([formats containsObject:@"Album"]) {
        return YES;
    } else if([formats containsObject:@"Vinyl"]) {
        return YES;
    } else if([formats containsObject:@"CD"]) {
        return YES;
    } else if([formats containsObject:@"EP"]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isASingle
{
    NSArray *formats = self.formats;
    if([formats containsObject:@"Single"]) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Private stuff
//actual reason for the asterisk: http://www.discogs.com/help/quick-start-guide.html#ANV
+ (NSString *)removeRandomAsteriskAtEndOfNamesIfPresent:(NSString *)originalName
{
    NSString *someRegexp = @".*\\*($|[^\\*])";
    NSPredicate *regex = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", someRegexp];
    if ([regex evaluateWithObject:originalName] && originalName.length > 0){
        return [originalName substringToIndex:originalName.length-1];  //index is exclusive
    } else {
        return originalName;
    }
}

+ (NSString *)removeNumberedSuffixIndicatingDupArtistOrAlbumInDiscogs:(NSString *)originalName
{
    //pmatches any numbers within () that are at the end of the string.
    NSString *regex = @" +(\\([0-9]+\\) *)$";  //pattern in quotes:   " +(\([0-9]+\) *)$"
    return [MZCommons deleteCharsMatchingRegex:regex usingString:originalName];
}

+ (NSArray *)parseFeatArtists:(NSString *)artistTitle
{
    NSArray *featArtists = nil;
    //first handle the case where there are two featured people:
    featArtists = [self findFeaturedArtists:artistTitle];
    
    if(featArtists.count == 0) {
        //now handle the case where there is just one featured person
        featArtists = [self findFeaturedArtist:artistTitle];
    }
    return featArtists;
}

//WARNING: if updated the regex in this method, update it in YouTubeVideo.m too.
//There is a similar method that performs this logic in that class.
+ (NSArray *)findFeaturedArtists:(NSString *)artistTitle
{
    //Example: YOLO (ft. Adam Levine & Kendrick Lamar)
    //in example, Adam Levine is capture group # 2. Kendrick Lamar is #4.
    NSString *regexExp = MZRegexMatchFeaturedArtists;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexExp
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSArray *matches = [regex matchesInString:artistTitle
                                      options:0
                                        range:NSMakeRange(0, [artistTitle length])];
    NSMutableArray *featArtists = [NSMutableArray arrayWithCapacity:2];
    if(matches.count > 0) {
        NSTextCheckingResult *match = matches[0];
        //indecies of the capture groups we care about:
        int captureGroup1stFeat = 2;  //1st featured artist
        int captureGroup2ndFeat = 4;  //2nd featured artist
        [featArtists addObject:[artistTitle substringWithRange:[match rangeAtIndex:captureGroup1stFeat]]];
        [featArtists addObject:[artistTitle substringWithRange:[match rangeAtIndex:captureGroup2ndFeat]]];
    }
    return featArtists;
}

//WARNING: if updated the regex in this method, update it in YouTubeVideo.m too.
//There is a similar method that performs this logic in that class.
+ (NSArray *)findFeaturedArtist:(NSString *)artistTitle
{
    //Example: YOLO (feat. Adam Levine )
    //in example, Adam Levine is capture group #2
    NSString *regexExp = MZRegexMatchFeaturedArtist;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexExp
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSArray *matches = [regex matchesInString:artistTitle
                                      options:0
                                        range:NSMakeRange(0, [artistTitle length])];
    if(matches.count > 0) {
        NSTextCheckingResult *match = matches[0];
        //index of the capture group we care about:
        int captureGroupFeatArtist = 2;  //the featured artist
        return @[[artistTitle substringWithRange:[match rangeAtIndex:captureGroupFeatArtist]]];
    }
    return @[];
}

@end
