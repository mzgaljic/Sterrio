//
//  YouTubeVideo.m
//  zTunes
//
//  Created by Mark Zgaljic on 8/1/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YouTubeVideo.h"

@implementation YouTubeVideo

- (NSString *)sanitizedTitle
{
    NSString *temp = [self removeExtraneousWhitespaceOnTarget:[self.videoName copy]];
    NSMutableString *title = [NSMutableString stringWithString:temp];
    
    [self removeVideoQualityStuffFromTitleOnTarget:&title];
    
    [self deleteSubstring:@"official lyric video" onTarget:&title];
    [self deleteSubstring:@"official music video" onTarget:&title];
    [self deleteSubstring:@"official video" onTarget:&title];

    [self deleteSubstring:@"lyrics" onTarget:&title];
    [self deleteSubstring:@"with lyrics" onTarget:&title];
    [self deleteSubstring:@"~" onTarget:&title];
    
    [self deleteSubstring:@"audio and video" onTarget:&title];
    [self deleteSubstring:@"audio & video" onTarget:&title];
    [self deleteSubstring:@"download link" onTarget:&title];
    [self deleteSubstring:@"audio & video" onTarget:&title];

    
    [self removeEmptyParensBracesOrBracketsOnTarget:&title];
    return title;
}

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
    NSArray *regexes = @[
                         //match on (    )
                         [NSRegularExpression regularExpressionWithPattern:@"\(\\s+\\)"
                                                                   options:0
                                                                     error:nil],
                         //match on [    ]
                         [NSRegularExpression regularExpressionWithPattern:@"\[\\s+\\]"
                                                                   options:0
                                                                     error:nil],
                         //match on {    }
                         [NSRegularExpression regularExpressionWithPattern:@"\{\\s+\\}"
                                                                   options:0
                                                                     error:nil]
                         ];
    for(NSRegularExpression *regex in regexes) {
        [regex replaceMatchesInString:*aString
                              options:0
                                range:NSMakeRange(0, [*aString length])
                         withTemplate:@""];
    }
}

- (void)removeSongDiscStuffOnTarget:(NSMutableString **)aString
{
    //match on "disc 1", "Disc 3", etc.
    NSRegularExpression *discRegex = [NSRegularExpression regularExpressionWithPattern:@"\(\\s+\\)"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
    [discRegex replaceMatchesInString:*aString
                              options:0
                                range:NSMakeRange(0, [*aString length])
                         withTemplate:@""];
}

- (NSString *)removeExtraneousWhitespaceOnTarget:(NSString *)aString
{
    //from: http://stackoverflow.com/a/12137128/4534674
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"  +" options:NSRegularExpressionCaseInsensitive error:nil];
    return [regex stringByReplacingMatchesInString:aString
                                           options:0
                                             range:NSMakeRange(0, aString.length)
                                      withTemplate:@" "];
}

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
    
    [self deleteSubstring:@"hq" onTarget:aString];
    [self deleteSubstring:@"high quality" onTarget:aString];
    [self deleteSubstring:@"high quality video" onTarget:aString];
    [self deleteSubstring:@"cd" onTarget:aString];
    [self deleteSubstring:@"recording" onTarget:aString];
    [self deleteSubstring:@"flac version" onTarget:aString];
    [self deleteSubstring:@"cd version" onTarget:aString];
    [self deleteSubstring:@"mp3 version" onTarget:aString];
    [self deleteSubstring:@"HD" onTarget:aString];
    [self deleteSubstring:@".mp4" onTarget:aString];
    [self deleteSubstring:@".mp3" onTarget:aString];
}
@end