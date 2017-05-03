//
//  YouTubeVideo.m
//  zTunes
//
//  Created by Mark Zgaljic on 8/1/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YouTubeVideo.h"

@interface YouTubeVideo ()
@end

@implementation YouTubeVideo

- (NSString *)sanitizedTitle
{
    NSMutableString *title = [self replaceWhitespacePaddedWordsWithSingleWhitespace:[self.videoName copy]];
    
    BOOL liveTextFound = NO;
    [self removeExtraHypensOnTarget:&title];
    [self removeVeryNicheKeywordsOnTarget:&title];
    [self removeVideoQualityStuffFromTitleOnTarget:&title];
    [self removeSongDiscInfoOnTarget:&title];
    
    [self deleteSubstring:@"official lyric video" onTarget:&title];
    [self deleteSubstring:@"official music video" onTarget:&title];
    [self deleteSubstring:@"official hd lyric video" onTarget:&title];
    [self deleteSubstring:@"official hd music video" onTarget:&title];
    [self deleteSubstring:@"official video" onTarget:&title];
    [self deleteSubstring:@"lyric video" onTarget:&title];
    [self deleteSubstring:@"music video" onTarget:&title];
    [self deleteSubstring:@"new music video" onTarget:&title];
    [self deleteSubstring:@"full song" onTarget:&title];
    [self deleteSubstring:@"new song" onTarget:&title];
    [self deleteSubstring:@"full album" onTarget:&title];
    [self deleteSubstring:@"new album" onTarget:&title];
    [self deleteSubstring:@"entire song" onTarget:&title];
    [self deleteSubstring:@"entire album" onTarget:&title];
    [self deleteSubstring:@"short version" onTarget:&title];
    [self deleteSubstring:@"long version" onTarget:&title];
    [self deleteSubstring:@"full version" onTarget:&title];
    
    [self deleteSubstring:@"w/ lyrics" onTarget:&title];
    [self deleteSubstring:@"with lyrics" onTarget:&title];
    [self deleteSubstring:@"lyrics" onTarget:&title];
    
    [self deleteSubstring:@"~" onTarget:&title];
    [self deleteSubstring:@"performed by" onTarget:&title];
    
    [self deleteSubstring:@"[audio]" onTarget:&title];
    [self deleteSubstring:@"(audio)" onTarget:&title];
    [self deleteSubstring:@"audio only" onTarget:&title];
    [self deleteSubstring:@"official audio" onTarget:&title];
    [self deleteSubstring:@"audio and video" onTarget:&title];
    [self deleteSubstring:@"audio & video" onTarget:&title];
    [self deleteSubstring:@"download link" onTarget:&title];
    [self deleteSubstring:@"audio & video" onTarget:&title];
    [self deleteSubstring:@"karaoke" onTarget:&title];
    [self deleteSubstring:@"karaoke version" onTarget:&title];
    if([self deleteSubstring:@"live performance" onTarget:&title]
       || [self deleteSubstring:@"[live]" onTarget:&title]
       || [self deleteSubstring:@"(live)" onTarget:&title])
    {
        liveTextFound = YES;
    }

    [self deleteSubstring:@"[explicit]" onTarget:&title];
    [self deleteSubstring:@"(explicit)" onTarget:&title];
    [self deleteSubstring:@"[explicit version]" onTarget:&title];
    [self deleteSubstring:@"(explicit version)" onTarget:&title];
    [self deleteSubstring:@"[us version]" onTarget:&title];
    [self deleteSubstring:@"(us version)" onTarget:&title];
    [self deleteSubstring:@"[uk version]" onTarget:&title];
    [self deleteSubstring:@"(uk version)" onTarget:&title];
    [self deleteSubstring:@"[soundtrack]" onTarget:&title];
    [self deleteSubstring:@"(soundtrack)" onTarget:&title];
    [self deleteSubstring:@"(official)" onTarget:&title];
    [self deleteSubstring:@"[official]" onTarget:&title];
    
    [self removeEmptyParensBracesOrBracketsOnTarget:&title];
    [self handleFeatKeywordsOnTarget:&title];
    if([self removeLiveKeywordsInParensOnTarget:&title]
       || [self removeLiveKeywordsToTheEndOfTheStringOnTarget:&title])
    {
        liveTextFound = YES;
    }
    [self removeEmptyParensBracesOrBracketsOnTarget:&title];
    
    self.isLivePerformance = (liveTextFound) ? YES : NO;
    return [title copy];
}

#pragma mark - Sub-routines
- (void)removeVideoQualityStuffFromTitleOnTarget:(NSMutableString **)aString
{
    [self deleteSubstring:@"144p" onTarget:aString];
    [self deleteSubstring:@"144 p" onTarget:aString];
    [self deleteSubstring:@"240p" onTarget:aString];
    [self deleteSubstring:@"240 p" onTarget:aString];
    [self deleteSubstring:@"360p" onTarget:aString];
    [self deleteSubstring:@"360 p" onTarget:aString];
    [self deleteSubstring:@"480p" onTarget:aString];
    [self deleteSubstring:@"480 p" onTarget:aString];
    [self deleteSubstring:@"560p" onTarget:aString];
    [self deleteSubstring:@"560 p" onTarget:aString];
    [self deleteSubstring:@"720p" onTarget:aString];
    [self deleteSubstring:@"720 p" onTarget:aString];
    [self deleteSubstring:@"1080p" onTarget:aString];
    [self deleteSubstring:@"1080 p" onTarget:aString];
    [self deleteSubstring:@"1440p" onTarget:aString];
    [self deleteSubstring:@"1440 p" onTarget:aString];
    [self deleteSubstring:@"720p" onTarget:aString];
    [self deleteSubstring:@"720 p" onTarget:aString];
    [self deleteSubstring:@"4k" onTarget:aString];
    [self deleteSubstring:@"8k" onTarget:aString];
    
    [self deleteSubstring:@"128kbps" onTarget:aString];
    [self deleteSubstring:@"128 kbps" onTarget:aString];
    [self deleteSubstring:@"256kbps" onTarget:aString];
    [self deleteSubstring:@"256 kbps" onTarget:aString];
    [self deleteSubstring:@"320kbps" onTarget:aString];
    [self deleteSubstring:@"320 kbps" onTarget:aString];
    
    [self deleteSubstring:@"hq" onTarget:aString];
    [self deleteSubstring:@"high quality" onTarget:aString];
    [self deleteSubstring:@"very quality" onTarget:aString];
    [self deleteSubstring:@"lossless quality" onTarget:aString];
    [self deleteSubstring:@"high quality video" onTarget:aString];
    [self deleteSubstring:@"cd" onTarget:aString];
    [self deleteSubstring:@"recording" onTarget:aString];
    [self deleteSubstring:@"drum cover" onTarget:aString];
    [self deleteSubstring:@"guitar cover" onTarget:aString];
    [self deleteSubstring:@"vocal cover" onTarget:aString];
    [self deleteSubstring:@"flac version" onTarget:aString];
    [self deleteSubstring:@"cd version" onTarget:aString];
    [self deleteSubstring:@"mp3 version" onTarget:aString];
    [self deleteSubstring:@"HD" onTarget:aString];
    [self deleteSubstring:@"*HD*" onTarget:aString];
    [self deleteSubstring:@".mp4" onTarget:aString];
    [self deleteSubstring:@".mp3" onTarget:aString];
}

- (void)removeVeryNicheKeywordsOnTarget:(NSMutableString **)aString
{
    //justin biebers YT video
    [self deleteSubstring:@"purpose : the movement" onTarget:aString];
    
    //Frozen song by demi lovato
    [self deleteSubstring:@"(from \"Frozen\")" onTarget:aString];
}

#pragma mark - Utility methods
- (BOOL)deleteSubstring:(NSString *)subStringToRemove onTarget:(NSMutableString **)aString
{
    NSRange range = [*aString rangeOfString:subStringToRemove options:NSCaseInsensitiveSearch];
    if(range.location == NSNotFound) {
        return NO;
    }
    [*aString deleteCharactersInRange:range];
    return YES;
}

- (void)removeEmptyParensBracesOrBracketsOnTarget:(NSMutableString **)aString
{
    //match on (  ) or (  -  ) or (  \  ) or (  /  ) or ( | ) w/ 0+ spaces
    NSString *parensPattern = @"\\\(\\s*-*\\s*\\/*\\s*\\\\*\\s*\\|*\\s*\\)";
    
    //match on [  ] or [  -  ] or [  \  ] or [ /  ] or [ | ] w/ 0+ spaces
    NSString *bracketPattern = @"\\\[\\s*-*\\s*\\/*\\s*\\\\*\\s*\\|*\\s*\\]";
    
    //match on {  } or {  -  } or {  \  } or {  /  } or { | } w/ 0+ spaces
    NSString *bracesPattern = @"\\\{\\s*-*\\s*\\/*\\s*\\\\*\\s*\\|*\\s*\\}";
    
    [MZCommons deleteCharsMatchingRegex:parensPattern onString:aString];
    [MZCommons deleteCharsMatchingRegex:bracketPattern onString:aString];
    [MZCommons deleteCharsMatchingRegex:bracesPattern onString:aString];
}

- (void)handleFeatKeywordsOnTarget:(NSMutableString **)aString
{
    NSArray *featArtists = nil;
    //first handle the case where there are two featured people:
    featArtists = [self findFeaturedArtistsInVideoTitle:aString];
    
    if(featArtists.count == 0) {
        //now handle the case where there is just one featured person
        featArtists = [self findFeaturedArtistInVideoTitle:aString];
    }
    self.featuredArtists = featArtists;
    
    //now that we've extracted the featured artists (if any), finish sanitizing title.
    NSString *regexExp = MZRegexMatchFeatAndFtToEndOfString;
    [MZCommons deleteCharsMatchingRegex:regexExp onString:aString];
}

//WARNING: if updated the regex in this method, update it in DiscogsItem.m too.
//There is a similar method that performs this logic in that class.
- (NSArray *)findFeaturedArtistsInVideoTitle:(NSMutableString **)aString
{
    //Example: YOLO (ft. Adam Levine & Kendrick Lamar)
    //in example, Adam Levine is capture group # 2. Kendrick Lamar is #4.
    NSString *regexExp = MZRegexMatchFeaturedArtists;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexExp
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:nil];
    NSArray *matches = [regex matchesInString:*aString
                                       options:0
                                         range:NSMakeRange(0, [*aString length])];
    NSMutableArray *featArtists = [NSMutableArray arrayWithCapacity:2];
    if(matches.count > 0) {
        NSTextCheckingResult *match = matches[0];
        //indecies of the capture groups we care about:
        int captureGroup1stFeat = 2;  //1st featured artist
        int captureGroup2ndFeat = 4;  //2nd featured artist
        
        [featArtists addObject:[*aString substringWithRange:[match rangeAtIndex:captureGroup1stFeat]]];
        [featArtists addObject:[*aString substringWithRange:[match rangeAtIndex:captureGroup2ndFeat]]];
    }
    return featArtists;
}

//WARNING: if updated the regex in this method, update it in DiscogResultUtils too.
//There is a similar method that performs this logic on a DiscogsItem
- (NSArray *)findFeaturedArtistInVideoTitle:(NSMutableString **)aString
{
    //Example: YOLO (feat. Adam Levine )
    //in example, Adam Levine is capture group #2
    NSString *regexExp = MZRegexMatchFeaturedArtist;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexExp
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:nil];
    NSArray *matches = [regex matchesInString:*aString
                              options:0
                                range:NSMakeRange(0, [*aString length])];
    if(matches.count > 0) {
        NSTextCheckingResult *match = matches[0];
        //index of the capture group we care about:
        int captureGroupFeatArtist = 2;  //the featured artist
        return @[[*aString substringWithRange:[match rangeAtIndex:captureGroupFeatArtist]]];
    }
    return @[];
}

- (void)removeSongDiscInfoOnTarget:(NSMutableString **)aString
{
    NSString *regexExp1 = @"(disc|disk) \\d+";
    NSString *regexExp2 = @"(disk|disc) \\d+ of \\d+";
    [MZCommons deleteCharsMatchingRegex:regexExp1 onString:aString];
    [MZCommons deleteCharsMatchingRegex:regexExp2 onString:aString];
}

- (BOOL)removeLiveKeywordsInParensOnTarget:(NSMutableString **)aString
{
    //matches (live on .....) or [live at .....], etc.
    //pattern:  \s+(\(|\[|{)\s*live\s+(at|@|in|on)\s+([^\)\]\}]*)(\)|\]|\})
    NSString *regexExp = @"\\s+(\\(|\\[|\\{)\\s*live\\s+(at|@|in|on)\\s+([^\\)\\]\\}]*)(\\)|\\]|\\})";
    return [MZCommons deleteCharsMatchingRegex:regexExp onString:aString];
}

- (BOOL)removeLiveKeywordsToTheEndOfTheStringOnTarget:(NSMutableString **)aString
{
    //if 'Live at', 'Live in', etc are present in the string (and not surrounded by parens
    //then remove those keywords and any additional stuff after it in a greedy attempt
    //to sanitize the string.
    
    //pattern: [^\(\[\{](Live at |in |on )
    NSString *regex = @"[^\\(\\[\\{](Live at |in |on )";
    NSRange range = [*aString rangeOfString:regex options:NSRegularExpressionSearch];
    BOOL matches = range.location != NSNotFound;
    if(matches) {
       return [MZCommons deleteCharsMatchingRegex:@"\\s+Live\\s+(at|in|on)\\s+.*" onString:aString];
    }
    return NO;
}

/* Handles regualr hyphen, en dash, and em dash. */
- (void)removeExtraHypensOnTarget:(NSMutableString **)aString
{
    NSString *hypen = @"-{2,}";
    NSString *enDash = @"–{2,}";
    NSString *emDash = @"—{2,}";
    [MZCommons replaceCharsMatchingRegex:hypen withChars:@"-" onString:aString];
    [MZCommons replaceCharsMatchingRegex:enDash withChars:@"–" onString:aString];
    [MZCommons replaceCharsMatchingRegex:emDash withChars:@"—" onString:aString];
}

- (NSMutableString *)replaceWhitespacePaddedWordsWithSingleWhitespace:(NSString *)aString
{
    //from: http://stackoverflow.com/a/12137128/4534674
    NSString *regexExp = @"  +";
    return [MZCommons replaceCharsMatchingRegex:regexExp withChars:@" " usingString:aString];
}

@end
