//
//  NSString+WhiteSpace_Utility.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/25/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (WhiteSpace_Utility)

/**Trims 'heading' and 'trailing' whitespace in a string. 
 Whitespace between meaningful characters is NOT removed.*/
- (NSString *)removeIrrelevantWhitespace;

@end
