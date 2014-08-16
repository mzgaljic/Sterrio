//
//  NSString+Levenshtein_Distance.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/15/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "NSString+Levenshtein_Distance.h"

@implementation NSString (Levenshtein_Distance)
- (NSUInteger)levenshteinDistanceToString:(NSString *)string
{
    NSString *myself = [self uppercaseStringWithLocale:[NSLocale currentLocale]];
    string = [string uppercaseStringWithLocale:[NSLocale currentLocale]];
    NSUInteger sl = [self length];
    NSUInteger tl = [string length];
    NSUInteger *d = calloc(sizeof(*d), (sl+1) * (tl+1));
    
#define d(i, j) d[((j) * sl) + (i)]
    for (NSUInteger i = 0; i <= sl; i++) {
        d(i, 0) = i;
    }
    for (NSUInteger j = 0; j <= tl; j++) {
        d(0, j) = j;
    }
    for (NSUInteger j = 1; j <= tl; j++) {
        for (NSUInteger i = 1; i <= sl; i++) {
            if ([myself characterAtIndex:i-1] == [string characterAtIndex:j-1]) {
                d(i, j) = d(i-1, j-1);
            } else {
                d(i, j) = MIN(d(i-1, j), MIN(d(i, j-1), d(i-1, j-1))) + 1;
            }
        }
    }
    
    NSUInteger r = d(sl, tl);
#undef d
    
    free(d);
    
    return r;
}
@end