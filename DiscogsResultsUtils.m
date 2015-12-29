//
//  DiscogsSearchUtils.m
//  Sterrio
//
//  Created by Mark Zgaljic on 12/28/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import "DiscogsResultsUtils.h"
#import "LevenshteinDistanceItem.h"
#import "NSString+Levenshtein_Distance.h"

@implementation DiscogsResultsUtils

+ (void)applyConfidenceLevelsToDiscogsItemsForResults:(NSArray **)discogsItems
                                         youtubeVideo:(YouTubeVideo *)ytVideo
{
    NSString *videoTitle = ytVideo.videoName;
    for(NSUInteger i = 0; i < (*discogsItems).count; i++) {
        DiscogsItem *item = (*discogsItems)[i];
        BOOL albumNameInTitle = ([videoTitle rangeOfString:item.albumName].location != NSNotFound);
        BOOL artistNameInTitle = ([videoTitle rangeOfString:item.artistName].location != NSNotFound);
        
        if (albumNameInTitle && artistNameInTitle) {
            item.matchConfidence = MatchConfidence_HIGH;
        } else if(albumNameInTitle || artistNameInTitle){
            item.matchConfidence = MatchConfidence_MEDIUM;
        } else {
            item.matchConfidence = MatchConfidence_LOW;
        }
    }
}

+ (NSUInteger)indexOfBestMatchFromResults:(NSArray *)discogsItems
{
    NSUInteger firstHighConfidenceIndex = NSNotFound;
    NSUInteger firstMediumConfidenceIndex = NSNotFound;
    for(NSUInteger i = 0; i < discogsItems.count; i++) {
        DiscogsItem *item = discogsItems[i];
        if(item.matchConfidence == MatchConfidence_HIGH) {
            firstHighConfidenceIndex = i;
        } else if(item.matchConfidence == MatchConfidence_MEDIUM) {
            firstMediumConfidenceIndex = i;
        }
    }
    return (firstHighConfidenceIndex == NSNotFound) ?   firstMediumConfidenceIndex
                                                        :
                                                        firstHighConfidenceIndex;
}

+ (void)applySongNameToDiscogsItem:(DiscogsItem **)discogsItem youtubeVideo:(YouTubeVideo *)ytVideo
{
    //copy so we don't pollute internal cache
    NSMutableString *sanitizedTitle = [NSMutableString stringWithString:[[ytVideo sanitizedTitle] copy]];
    [DiscogsResultsUtils removeRandomHyphensIfPresent:&sanitizedTitle];
    [DiscogsResultsUtils deleteSubstring:(*discogsItem).artistName onTarget:&sanitizedTitle];
    [DiscogsResultsUtils deleteSubstring:(*discogsItem).albumName onTarget:&sanitizedTitle];
    (*discogsItem).songName = sanitizedTitle;
}

#pragma mark - utility method
+ (void)deleteSubstring:(NSString *)subStringToRemove onTarget:(NSMutableString **)aString
{
    if(subStringToRemove == nil){
        return;
    }
    
    NSRange range = [*aString rangeOfString:subStringToRemove options:NSCaseInsensitiveSearch];
    if(range.location == NSNotFound) {
        return;
    }
    [*aString deleteCharactersInRange:range];
}

+ (void)removeRandomHyphensIfPresent:(NSMutableString **)aString
{
    NSString *parensPattern = @"\\s((-)|(--))\\s";  //matches ...-... or ...--...
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:parensPattern
                                                                           options:0
                                                                             error:nil];
    [regex replaceMatchesInString:*aString
                          options:0
                            range:NSMakeRange(0, [*aString length])
                     withTemplate:@""];
}

@end
