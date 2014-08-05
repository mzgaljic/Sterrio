//
//  NSString+HTTP_Char_Escape.m
//  zTunes
//
//  Created by Mark Zgaljic on 8/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "NSString+HTTP_Char_Escape.h"

@implementation NSString (HTTP_Char_Escape)

- (NSString *)stringForHTTPRequest
{
    return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                     (CFStringRef)self,
                                                                     NULL,
                                                                     (CFStringRef)@":/?@!$&'()*+,;=",
                                                                     kCFStringEncodingUTF8));
}

@end
