//
//  NSString+HTTP_Char_Escape.h
//  zTunes
//
//  Created by Mark Zgaljic on 8/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (HTTP_Char_Escape)

- (NSString *)stringForHTTPRequest;

@end
