//
//  GenreConstants.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/31/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GenreConstants : NSObject

+ (NSArray *)alphabeticallySortedUserPresentableArrayOfGenreStringsAvailable;  //good for showing all posibilities
+ (NSArray *)unsortedRawArrayOfGenreStringsAvailable;  //good for searching

/**
 Returns -1 if corresponding genre code isn't found (ie: invalid genre string provided). If a corresponding genre code IS found, its
 non-negative value shall be returned. */
+ (int)genreStringToCode:(NSString *)aGenreString;

/**
 Returns nil if corresponding genre string isn't found (ie: invalid genre code provided). If a corresponding genre string IS found, its
 non-nil value shall be returned. */
+ (NSString *)genreCodeToString:(int)aGenreCode;


+ (NSString *)noGenreSelectedGenreString;
+ (int)noGenreSelectedGenreCode;
+ (BOOL)isValidGenreCode:(int)aGenreCode;

@end