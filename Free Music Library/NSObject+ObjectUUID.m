//
//  NSObject+ObjectUUID.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/26/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "NSObject+ObjectUUID.h"

@implementation NSObject (ObjectUUID)

+ (NSString *)UUID
{
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    NSString * uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    CFRelease(newUniqueId);
    return uuidString;
}



@end
