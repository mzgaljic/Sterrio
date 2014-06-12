//
//  MusicModel.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//
//use MusicModelUtility for obtaining sorted lists...The dictionary here simply lets you easily get the id# of a specific content item.
#import <Foundation/Foundation.h>

@interface MusicModel : NSObject
//initialization
+ (instancetype)createSingleton;

//Objects from dictionaries are GUI-friendly.
@property (atomic, strong) NSMutableDictionary *albumDictionary;
@property (atomic, strong) NSMutableDictionary *songDictionary;
@property (atomic, strong) NSMutableDictionary *genreDictionary;
@property (atomic, strong) NSMutableDictionary *playlistDictionary;
@property (atomic, strong) NSMutableDictionary *artistDictionary;

//constant for missing/unprovided id values in SQL DB.
@property (nonatomic, readonly) int NO_ID_VALUE;
@end
