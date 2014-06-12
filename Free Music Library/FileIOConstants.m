//
//  FileIOConstants.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/12/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "FileIOConstants.h"

@implementation FileIOConstants
static NSURL *url = nil;

+ (instancetype)createSingleton
{
    static id sharedMyModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyModel = [[self alloc] init];
    });
    return sharedMyModel;
}

- (NSURL *)libraryFileURL
{
    return url;
}

- (void)setLibraryFileURL:(NSURL *)aUrl
{
    url = aUrl;
}

@end
