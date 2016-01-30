//
//  DiscogsSearchUtils.m
//  Sterrio
//
//  Created by Mark Zgaljic on 12/28/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import "DiscogsResultsUtils.h"
#import "NSString+WhiteSpace_Utility.h"

@implementation DiscogsResultsUtils

+ (void)applyConfidenceLevelsToDiscogsItemsForResults:(NSArray **)discogsItems
                                         youtubeVideo:(YouTubeVideo *)ytVideo
{
    NSString *videoTitle = ytVideo.videoName;
    for(NSUInteger i = 0; i < (*discogsItems).count; i++) {
        DiscogsItem *item = (*discogsItems)[i];
        BOOL albumNameInTitle = ([videoTitle rangeOfString:item.albumName].location != NSNotFound);
        BOOL artistNameInTitle = ([videoTitle rangeOfString:item.artistName].location != NSNotFound);
        
        //do a quick sanity check - was the YT video published in an eariler year?
        //If so, it obviously isn't a match (unless it is 1 year earlier, in which
        //case we still consider it in case it was a pre-release on VEVO, etc.)
        int videoPublishYear = [self yearFromNSDate:ytVideo.publishDate];
        if(videoPublishYear < item.releaseYear && abs(videoPublishYear - item.releaseYear) > 1) {
            item.matchConfidence = MatchConfidence_LOW;
            continue;
        }
            
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
    NSMutableString *sanitizedTitle = [NSMutableString stringWithString:[[[ytVideo sanitizedTitle] removeIrrelevantWhitespace] copy]];
    [DiscogsResultsUtils removeRandomHyphensIfPresent:&sanitizedTitle];
    [DiscogsResultsUtils deleteSubstring:(*discogsItem).artistName onTarget:&sanitizedTitle];
    [DiscogsResultsUtils deleteSubstring:(*discogsItem).albumName onTarget:&sanitizedTitle];
    
    //some video titles contain 1 char or more of whitespace in front which the method
    //[NSString removeIrrelevantWhitespace] does not handle for some reason! Handling that now...
    while(sanitizedTitle.length > 0 && [sanitizedTitle characterAtIndex:0] == ' ') {
        [sanitizedTitle deleteCharactersInRange:NSMakeRange(0, 1)];
    }
    
    //if after removing the album and artist names from the video title we are left with just
    //"________", then we should remove the quotes from the title! This typically occurs
    //if the song name is in quotes within the title itself. Note in this if we check for the
    // \ char as well since that is how the title is given to use by the YouTube APIs.
    if(sanitizedTitle.length >= 2
       && [sanitizedTitle characterAtIndex:0] == '\"'
       && [sanitizedTitle characterAtIndex:sanitizedTitle.length-1] == '\"') {
        [sanitizedTitle deleteCharactersInRange:NSMakeRange(sanitizedTitle.length-1, 1)];
        [sanitizedTitle deleteCharactersInRange:NSMakeRange(0, 1)];
    }
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

+ (int)yearFromNSDate:(NSDate *)aDate
{
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:aDate];
    return (int)[comps year];
}

@end
