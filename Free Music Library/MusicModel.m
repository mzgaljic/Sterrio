//
//  MusicModel.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MusicModel.h"

@implementation MusicModel
@synthesize albumArray = _albumArray, songArray = _songArray, genreArray = _genreArray,
playlistArray = _playlistArray, artistArray = _artistArray;

+ (instancetype)createSingleton
{
    static id sharedMyModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyModel = [[self alloc] init];
    });
    return sharedMyModel;
}

@end
