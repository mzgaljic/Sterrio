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

+ (NSArray<NSNumber*> *)getConfidenceLevelsForDiscogsItemResults:(NSArray *)discogsItems
                                                    youtubeVideo:(YouTubeVideo *)ytVideo
{
    NSMutableArray *confidenceLevels = [NSMutableArray arrayWithCapacity:discogsItems.count];
    for(DiscogsItem *item in discogsItems) {
        if(item.matchConfidence != MatchConfidence_UNDEFINED) {
            [confidenceLevels addObject:@(item.matchConfidence)];
            continue;
        }
        
        NSString *videoTitle = ytVideo.videoName;
        NSRange albumNameRange = [videoTitle rangeOfString:item.albumName
                                                   options:NSCaseInsensitiveSearch];
        NSRange artistNameRange = [videoTitle rangeOfString:item.artistName
                                                    options:NSCaseInsensitiveSearch];
        BOOL albumNameInTitle = (albumNameRange.location != NSNotFound);
        BOOL artistNameInTitle = (artistNameRange.location != NSNotFound);
        
        //do a quick sanity check - was the YT video published in an eariler year?
        //If so, it obviously isn't a match (unless it is 1 year earlier, in which
        //case we still consider it in case it was a pre-release on VEVO, etc.)
        int videoPublishYear = [self yearFromNSDate:ytVideo.publishDate];
        if(videoPublishYear < item.releaseYear && abs(videoPublishYear - item.releaseYear) > 1) {
            [confidenceLevels addObject:@(MatchConfidence_LOW)];
            continue;
        }
        
        //does the album name for this suggestion contain the text "live at" or "live in"?
        //if so, limit the confidence to a max confidence of MEDIUM. We prefer non-live results
        //if possible.
        NSRange liveAtRange = [videoTitle rangeOfString:@"live at"
                                                options:NSCaseInsensitiveSearch];
        NSRange liveInRange = [videoTitle rangeOfString:@"live in"
                                                options:NSCaseInsensitiveSearch];
        
        //isAlbumVinylCDOrEP must be first in if statement, otherwise it may not be executed.
        if ([item isAlbumVinylCDOrEP] && ![item isASingle]
            && albumNameInTitle && artistNameInTitle
            && liveAtRange.location == NSNotFound
            && liveInRange.location == NSNotFound) {
            [confidenceLevels addObject:@(MatchConfidence_VERY_HIGH)];
            
        } else if([item isAlbumVinylCDOrEP] && ![item isASingle]
                  && albumNameInTitle && artistNameInTitle) {
            [confidenceLevels addObject:@(MatchConfidence_HIGH_HIGH)];
            
        } else if([item isAlbumVinylCDOrEP] && ![item isASingle] && artistNameInTitle) {
            [confidenceLevels addObject:@(MatchConfidence_HIGH_MEDIUM)];

        } else if([item isAlbumVinylCDOrEP] && albumNameInTitle && artistNameInTitle) {
            [confidenceLevels addObject:@(MatchConfidence_HIGH_LOW)];
            
        } else if([item isAlbumVinylCDOrEP] && ![item isASingle]
                  && (albumNameInTitle || artistNameInTitle)) {
            [confidenceLevels addObject:@(MatchConfidence_MEDIUM_HIGH)];
            
        } else if([item isAlbumVinylCDOrEP] && (albumNameInTitle || artistNameInTitle)) {
            [confidenceLevels addObject:@(MatchConfidence_MEDIUM)];
            
        } else if(albumNameInTitle && artistNameInTitle) {
            [confidenceLevels addObject:@(MatchConfidence_MEDIUM)];
            
        }  else if(albumNameInTitle || artistNameInTitle) {
            [confidenceLevels addObject:@(MatchConfidence_MEDIUM_LOW)];
            
        } else {
            [confidenceLevels addObject:@(MatchConfidence_LOW)];
        }
    }
    return confidenceLevels;
}

+ (NSUInteger)indexOfBestMatchFromResults:(NSArray *)discogsItems
{
    NSUInteger firstVeryHighConfidenceIndex = NSNotFound;
    NSUInteger firstHighHighConfidenceIndex = NSNotFound;
    NSUInteger firstHighMediumConfidenceIndex = NSNotFound;
    NSUInteger firstHighLowConfidenceIndex = NSNotFound;
    NSUInteger firstMediumHighConfidenceIndex = NSNotFound;
    NSUInteger firstMediumConfidenceIndex = NSNotFound;
    NSUInteger firstMediumLowConfidenceIndex = NSNotFound;
    for(NSUInteger i = 0; i < discogsItems.count; i++) {
        DiscogsItem *item = discogsItems[i];
        
        if(item.matchConfidence == MatchConfidence_VERY_HIGH
                && firstVeryHighConfidenceIndex == NSNotFound) {
            firstVeryHighConfidenceIndex = i;
            
        } else if(item.matchConfidence == MatchConfidence_HIGH_HIGH
                  && firstHighHighConfidenceIndex == NSNotFound) {
            firstHighHighConfidenceIndex = i;
            
        } else if(item.matchConfidence == MatchConfidence_HIGH_MEDIUM
                  && firstHighMediumConfidenceIndex == NSNotFound) {
            firstHighMediumConfidenceIndex = i;
            
        } else if(item.matchConfidence == MatchConfidence_HIGH_LOW
                  && firstHighLowConfidenceIndex == NSNotFound) {
            firstHighLowConfidenceIndex = i;
            
        } else if(item.matchConfidence == MatchConfidence_MEDIUM_HIGH
                  && firstMediumHighConfidenceIndex == NSNotFound){
            firstMediumHighConfidenceIndex = i;
            
        } else if(item.matchConfidence == MatchConfidence_MEDIUM
                  && firstMediumConfidenceIndex == NSNotFound) {
            firstMediumConfidenceIndex = i;
            
        } else if(item.matchConfidence == MatchConfidence_MEDIUM_LOW
                  && firstMediumLowConfidenceIndex == NSNotFound) {
            firstMediumLowConfidenceIndex = i;
        }
    }
    
    if(firstVeryHighConfidenceIndex != NSNotFound) {
        return firstVeryHighConfidenceIndex;
    }
    if(firstHighHighConfidenceIndex != NSNotFound) {
        return firstHighHighConfidenceIndex;
    }
    if(firstHighMediumConfidenceIndex != NSNotFound) {
        return firstHighMediumConfidenceIndex;
    }
    if(firstHighLowConfidenceIndex != NSNotFound) {
        return firstHighLowConfidenceIndex;
    }
    if(firstMediumHighConfidenceIndex != NSNotFound) {
        return firstMediumHighConfidenceIndex;
    }
    if(firstMediumConfidenceIndex != NSNotFound) {
        return firstMediumConfidenceIndex;
    }
    
    return firstMediumLowConfidenceIndex;
}

+ (NSString *)analyzeAndGenerateCleanedSongNameWithItem:(DiscogsItem *)discogsItem
                                           youtubeVideo:(YouTubeVideo *)ytVideo
{
    //copy so we don't pollute internal cache
    NSString *temp = ytVideo.sanitizedTitle;
    NSMutableString *sanitizedTitle = [[NSMutableString alloc] initWithString:[temp removeIrrelevantWhitespace]];
    sanitizedTitle = [DiscogsResultsUtils deleteSubstring:discogsItem.artistName
                                               fromString:sanitizedTitle];
    sanitizedTitle = [DiscogsResultsUtils deleteSubstring:discogsItem.albumName
                                               fromString:sanitizedTitle];
    [DiscogsResultsUtils removeRandomHyphensIfPresent:&sanitizedTitle];
    
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
    
    //if after all parsing/logic happens we are left with just a dash,
    //ignore it and make the song name empty. After all, a dash is not
    //a real song name. Note: multiple dashes will never happen, they
    //are removed during the title sanitation process.
    NSString *hypen = @"-";
    NSString *enDash = @"–";
    NSString *emDash = @"—";
    if([sanitizedTitle isEqualToString:hypen]
       || [sanitizedTitle isEqualToString:enDash]
       || [sanitizedTitle isEqualToString:emDash]) {
        return @"";
    }

    //remove '-' from song name if it got there (can be missed by parsing - usually if
    //video title has poor punctuation.
    if([sanitizedTitle hasPrefix:hypen]) {
        [sanitizedTitle deleteCharactersInRange:[sanitizedTitle rangeOfString:hypen]];
    } else if([sanitizedTitle hasPrefix:enDash]) {
        [sanitizedTitle deleteCharactersInRange:[sanitizedTitle rangeOfString:enDash]];
    } else if([sanitizedTitle hasPrefix:emDash]) {
        [sanitizedTitle deleteCharactersInRange:[sanitizedTitle rangeOfString:emDash]];
    }
    
    [sanitizedTitle removeIrrelevantWhitespace];
    if(sanitizedTitle.length > 0 && ytVideo.featuredArtists.count > 0) {
        //lets consider the first one mentioned most important
        NSString *firstFeaturedArtist = ytVideo.featuredArtists[0];
        [sanitizedTitle appendString:@" ft. "];
        [sanitizedTitle appendString:firstFeaturedArtist];
    }
    
    if(sanitizedTitle.length > 0 && ytVideo.isLivePerformance) {
        NSRange range = [sanitizedTitle rangeOfString:@"live" options:NSCaseInsensitiveSearch];
        if(range.location == NSNotFound) {
            //We know the video is a live performance & the keywords 'live' aren't in
            //the song title. Lets append '(live)' at the end so user can differentiate
            //amongst other stuff in their album.
            [sanitizedTitle appendString:@" [live]"];
        }
    }
    return sanitizedTitle;
}

+ (NSString *)analyzeAndGenerateCleanedArtistNameWithItem:(DiscogsItem *)item
{
    NSString *artistSuggestion;
    if(item.featuredArtists.count == 0) {
        artistSuggestion = item.artistName;
    } else {
        artistSuggestion = [NSString stringWithFormat:@"%@ ft. %@", item.artistName, item.featuredArtists[0]];
    }
    return artistSuggestion;
}

+ (void)applyFinalArtistNameLogicForPresentation:(DiscogsItem **)discogsItem
{
    NSString *artistSuggestion;
    if((*discogsItem).featuredArtists.count == 0) {
        artistSuggestion = (*discogsItem).artistName;
    } else {
        artistSuggestion = [NSString stringWithFormat:@"%@ ft. %@",
                            (*discogsItem).artistName,
                            (*discogsItem).featuredArtists[0]];
    }
    (*discogsItem).artistName = artistSuggestion;
}

#pragma mark - utility methods
+ (NSMutableString *)deleteSubstring:(NSString *)subStringToRemove fromString:(NSMutableString *)aString
{
    if(subStringToRemove == nil){
        return nil;
    }
    
    NSRange range = [aString rangeOfString:subStringToRemove options:NSCaseInsensitiveSearch];
    if(range.location == NSNotFound) {
        return aString;
    }
    [aString deleteCharactersInRange:range];
    return aString;
}

+ (void)removeRandomHyphensIfPresent:(NSMutableString **)aString
{
    NSString *parensPattern = @"\\s((-)|(--))\\s";  //matches ...-... or ...--...
    [MZCommons deleteCharsMatchingRegex:parensPattern onString:aString];
}

+ (int)yearFromNSDate:(NSDate *)aDate
{
    return (int)[[[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:aDate] year];
}

@end
