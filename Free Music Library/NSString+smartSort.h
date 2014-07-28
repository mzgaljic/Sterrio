//
//  NSString+smartSort.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/19/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+WhiteSpace_Utility.h"

@interface NSString (smartSort)

/** Performs a smart sort comparison on the given string. 
 In smart sort, the words (a/an/the) are all ignored.*/
- (NSComparisonResult)smartSort:(NSString*)aString;

@end
