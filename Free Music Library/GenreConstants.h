//
//  GenreConstants.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/31/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GenreConstants : NSObject

@property (nonatomic, copy) NSDictionary *singletonGenreDictionary;
//initialization
+ (instancetype)createSingleton;  //change instancetype
+ (NSArray *)keysForGenreSingleton;
+ (NSArray *)objectsForGenreSingleton;

//using initialized singleton
+ (int)genreStringToCode:(NSString *)aGenreString;
+ (NSString *)genreCodeToString:(int)aGenreCode;

@end