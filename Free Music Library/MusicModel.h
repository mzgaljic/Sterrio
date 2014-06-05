//
//  MusicModel.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MusicModel : NSObject
//initialization
+ (instancetype)createSingleton;

//Objects from dictionaries are GUI-friendly.
@property (atomic, strong) NSMutableArray *albumArray;
@property (atomic, strong) NSMutableArray *songArray;
@property (atomic, strong) NSMutableArray *genreArray;
@property (atomic, strong) NSMutableArray *playlistArray;
@property (atomic, strong) NSMutableArray *artistArray;

@end
