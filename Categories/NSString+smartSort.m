//
//  NSString+smartSort.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/19/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "NSString+smartSort.h"

@implementation NSString (smartSort)
static NSString *myself;

// This method can be exposed in header
- (NSComparisonResult)smartSort:(NSString*)aString;
{
    //original, clean code...
    //NSString* selfTrimmed = [self removeArticles];
    //NSString *compareStringTrimmed = [aString removeArticles];
    //return [selfTrimmed compare:compareStringTrimmed];
    
    return [[self removeArticles] compare:[aString removeArticles]];  //equivalent one-liner
}

- (NSString*)removeArticles  //makes sure to resort strings that START with the specified prefixes.
{
    myself = self;
    myself = [myself removeIrrelevantWhitespace];
    
    NSRange range = NSMakeRange(NSNotFound, 0);
    
    if ([self hasPrefix:@"a "])
        range = [self rangeOfString:@"a "];
    else if ([self hasPrefix:@"A "])
        range = [self rangeOfString:@"A "];
    
    else if ([self hasPrefix:@"an "])
        range = [self rangeOfString:@"an "];
    else if ([self hasPrefix:@"An "])
        range = [self rangeOfString:@"An "];
    
    else if ([self hasPrefix:@"the "])
        range = [self rangeOfString:@"the "];
    else if ([self hasPrefix:@"The "])
        range = [self rangeOfString:@"The "];
    
    if (range.location != NSNotFound)
        return [self substringFromIndex:range.length];
    else
        return self;
}

- (NSString *)regularStringToSmartSortString
{
    return [self removeArticles];
}

@end
