//
//  NSString+Levenshtein_Distance.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/15/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

//found at http://rosettacode.org/wiki/Levenshtein_distance#Objective-C
@interface NSString (Levenshtein_Distance)

- (NSUInteger)computeLevenshteinDistanceFromSecondString:(NSString *)string;

@end
