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
@property (nonatomic, strong) NSString *cachedSanitizedTitle;
@end

@implementation YouTubeVideo

//useful when you need a temporary copy that keeps its own cachedSanitizedTitle ivar.
- (id)copyWithZone:(NSZone *)zone
{
    // Copying code here.
    YouTubeVideo *copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        copy.videoName = [self.videoName copyWithZone:zone];
        copy.videoId = [self.videoId copyWithZone:zone];
        copy.videoThumbnailUrl = [self.videoThumbnailUrl copyWithZone:zone];
        copy.videoThumbnailUrlHighQuality = [self.videoThumbnailUrlHighQuality copyWithZone:zone];
        copy.channelTitle = [self.channelTitle copyWithZone:zone];
        copy.publishDate = self.publishDate;
        copy.duration = self.duration;
    }
    return copy;
}

- (NSString *)sanitizedTitle
{
    if(self.cachedSanitizedTitle) {
        return self.cachedSanitizedTitle;
    }
    
    NSString *temp = [self replaceWhitespacePaddedWordsWithSingleWhitespace:[self.videoName copy]];
    NSMutableString *title = [NSMutableString stringWithString:temp];
    
    [self removeExtraHypensOnTarget:&title];
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
    [self deleteSubstring:@"live performance" onTarget:&title];
    [self deleteSubstring:@"[live]" onTarget:&title];
    [self deleteSubstring:@"(live)" onTarget:&title];
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
    
    [self removeVeryNicheKeywordsOnTarget:&title];
    [self removeEverythingFromFtToEndOnTarget:&title];
    [self removeLiveAtInParensOnTarget:&title];
    
    [self removeEmptyParensBracesOrBracketsOnTarget:&title];
    self.cachedSanitizedTitle = title;
    return title;
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
}

#pragma mark - Utility methods
- (void)deleteSubstring:(NSString *)subStringToRemove onTarget:(NSMutableString **)aString
{
    NSRange range = [*aString rangeOfString:subStringToRemove options:NSCaseInsensitiveSearch];
    if(range.location == NSNotFound) {
        return;
    }
    [*aString deleteCharactersInRange:range];
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

//looks for "ft." and removes everything starting from there to the end of the string (within.
- (void)removeEverythingFromFtToEndOnTarget:(NSMutableString **)aString
{
    NSString *regexExp = @"ft\\..*|feat\\..*";
    [MZCommons deleteCharsMatchingRegex:regexExp onString:aString];
}

- (void)removeSongDiscInfoOnTarget:(NSMutableString **)aString
{
    NSString *regexExp1 = @"(disc|disk) \\d+";
    NSString *regexExp2 = @"(disk|disc) \\d+ of \\d+";
    [MZCommons deleteCharsMatchingRegex:regexExp1 onString:aString];
    [MZCommons deleteCharsMatchingRegex:regexExp2 onString:aString];
}

- (void)removeLiveAtInParensOnTarget:(NSMutableString **)aString
{
    //matches (live on .....) or (live at .....), etc.
    NSString *regexExp = @"\\(\\s*live\\s*(at |in |on )\\s*([^\\)]*)\\)";
    [MZCommons deleteCharsMatchingRegex:regexExp onString:aString];
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

- (NSString *)replaceWhitespacePaddedWordsWithSingleWhitespace:(NSString *)aString
{
    //from: http://stackoverflow.com/a/12137128/4534674
    NSString *regexExp = @"  +";
    return [MZCommons replaceCharsMatchingRegex:regexExp withChars:@" " usingString:aString];
}

@end