//
//  GenreSearchDelegate.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/14/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GenreSearchDelegate <NSObject>

- (void)genreSearchDidCompleteWithResults:(NSArray *)arrayOfGenreStrings;

@end
