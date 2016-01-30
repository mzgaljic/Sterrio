//
//  MZCommons.m
//  Sterrio
//
//  Created by Mark Zgaljic on 1/27/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZCommons.h"

@implementation MZCommons

#pragma mark - Threads
void safeSynchronousDispatchToMainQueue(void (^block)(void))
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

#pragma mark - Regex Helpers
+ (void)replaceCharsMatchingRegex:(NSString *)pattern
                        withChars:(NSString *)replacementChars
                         onString:(NSMutableString **)regexMe
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    [regex replaceMatchesInString:*regexMe
                          options:0
                            range:NSMakeRange(0, [*regexMe length])
                     withTemplate:replacementChars];
}

+ (NSString *)replaceCharsMatchingRegex:(NSString *)pattern
                              withChars:(NSString *)replacementChars
                        usingString:(NSString *)regexMe
{
    NSMutableString *returnMe = [NSMutableString stringWithString:regexMe];
    [MZCommons replaceCharsMatchingRegex:pattern withChars:replacementChars onString:&returnMe];
    return returnMe;
}

+ (void)deleteCharsMatchingRegex:(NSString *)pattern onString:(NSMutableString **)regexMe
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    [regex replaceMatchesInString:*regexMe
                          options:0
                            range:NSMakeRange(0, [*regexMe length])
                     withTemplate:@""];
}

+ (NSString *)deleteCharsMatchingRegex:(NSString *)pattern usingString:(NSString *)regexMe
{
    NSMutableString *returnMe = [NSMutableString stringWithString:regexMe];
    [MZCommons deleteCharsMatchingRegex:pattern onString:&returnMe];
    return returnMe;
}

@end
