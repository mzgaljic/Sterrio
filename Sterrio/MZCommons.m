//
//  MZCommons.m
//  Sterrio
//
//  Created by Mark Zgaljic on 1/27/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZCommons.h"

@implementation MZCommons

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

+ (NSString *)deleteCharsMatchingRegex:(NSString *)pattern withString:(NSString *)regexMe
{
    NSMutableString *returnMe = [NSMutableString stringWithString:regexMe];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    [regex replaceMatchesInString:returnMe
                          options:0
                            range:NSMakeRange(0, [returnMe length])
                     withTemplate:@""];
    return returnMe;
}

@end
