//
//  NSString+WhiteSpace_Utility.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/25/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "NSString+WhiteSpace_Utility.h"

@implementation NSString (WhiteSpace_Utility)

- (NSString *)removeIrrelevantWhitespace
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
