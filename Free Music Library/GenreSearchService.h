//
//  GenreSearchService.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/14/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GenreSearchDelegate.h"
#import "GenreConstants.h"
#import "NSString+WhiteSpace_Utility.h"

@interface GenreSearchService : NSObject

+ (void)searchAllGenresForGenreString:(NSString *)searchString;
+ (void)setDelegate:(id<GenreSearchDelegate>)delegate;

@end
