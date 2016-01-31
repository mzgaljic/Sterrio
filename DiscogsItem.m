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
    NSString *urlString = @"https://api.discogs.com/database/search?type=master&type=album&per_page=6&page=1&q=";
    query = [query stringForHTTPRequest];
    NSURL *myUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", urlString, query]];
    NSMutableURLRequest *mutUrlRequest = [NSMutableURLRequest requestWithURL:myUrl];
    [mutUrlRequest setValue:[NSString stringWithFormat:@"%@ - iOS App", MZAppName]
         forHTTPHeaderField:@"User-Agent"];
    [mutUrlRequest setValue:@"Discogs token=CHSGmUCKHjNIOeAKgbuaBZUEldBInAopLpRJiGMc"
         forHTTPHeaderField:@"Authorization"];
    
    
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
        
        artistName = [self removeRandomAsteriskAtEndOfNamesIfPresent:artistName];
        albumName = [self removeRandomAsteriskAtEndOfNamesIfPresent:albumName];
        artistName = [self removeNumberedSuffixRepresentingDuplicateArtistOrAlbumInDiscogs:artistName];
        albumName = [self removeNumberedSuffixRepresentingDuplicateArtistOrAlbumInDiscogs:albumName];
        
        //the DiscogsItem songName is set in YouTubeSongAdderViewController when results are processed.
        DiscogsItem *item = [[DiscogsItem alloc] init];
        //if we detect a featured artist, the app appends 'ft.' to the end of the song name. But if the
        //album name contains 'Feat.', we should change it to 'ft.' to keep things consistent!
        item.artistName = [MZCommons replaceCharsMatchingRegex:@"\\s+Feat\\.\\s+"
                                                     withChars:@" ft. "
                                                   usingString:artistName];;
        item.albumName = albumName;
        item.releaseYear = year;
        item.formats = [resultsArray[i] objectForKey:@"format"];
        [itemsArray addObject:item];
    }
    return itemsArray;
}

- (BOOL)isAlbumOrVinylOrCd
{
    NSArray *formats = self.formats;
    if([formats containsObject:@"Album"]) {
        return YES;
    } else if([formats containsObject:@"Vinyl"]) {
        return YES;
    } else if([formats containsObject:@"CD"]) {
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

+ (NSString *)removeNumberedSuffixRepresentingDuplicateArtistOrAlbumInDiscogs:(NSString *)originalName
{
    //pmatches any numbers within () that are at the end of the string.
    NSString *regex = @" +(\\([0-9]+\\) *)$";  //pattern in quotes:   " +(\([0-9]+\) *)$"
    return [MZCommons deleteCharsMatchingRegex:regex usingString:originalName];
}

@end
