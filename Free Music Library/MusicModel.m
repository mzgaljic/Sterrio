//
//  MusicModel.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MusicModel.h"

@implementation MusicModel
@synthesize albumDictionary = _albumDictionary, songDictionary = _songDictionary, genreDictionary = _genreDictionary,
playlistDictionary = _playlistDictionary, artistDictionary = _artistDictionary, NO_ID_VALUE = _NO_ID_VALUE;

+ (instancetype)createSingleton
{
    static id sharedMyModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyModel = [[self alloc] init];
        [sharedMyModel setConstantHelper:-1];  //initialize this singletons constant
    });
    return sharedMyModel;
}

- (void)setConstantHelper:(int)value
{
    _NO_ID_VALUE = value;
}

@end
