//
//  GenreSearchService.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/14/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "GenreSearchService.h"

@interface GenreSearchService ()
@end

@implementation GenreSearchService
static id<GenreSearchDelegate>delegate;

+ (void)searchAllGenresForGenreString:(NSString *)searchString
{
    if(searchString.length == 0)
    {
        [delegate genreSearchDidCompleteWithResults:[NSArray array]];
    }
    else
    {
        searchString = [searchString removeIrrelevantWhitespace];
        NSArray *arrayOfGenreStrings = [GenreConstants unsortedRawArrayOfGenreStringsAvailable];
        NSMutableArray *resultArray = [NSMutableArray array];
        
        for(NSString *aGenreString in arrayOfGenreStrings)  //iterate through genre strings
        {
            NSRange nameRange = [aGenreString rangeOfString:searchString options:NSCaseInsensitiveSearch];
            if(nameRange.location != NSNotFound)
                [resultArray addObject:aGenreString];
        }
        [resultArray removeObject:[GenreConstants noGenreSelectedGenreString]];
        [GenreSearchService sortExistingGenreMutableArrayAlphabetically:&resultArray];
        
        [delegate genreSearchDidCompleteWithResults:resultArray];
    }
}

+ (void)setDelegate:(id<GenreSearchDelegate>)aDelegate
{
    delegate = aDelegate;
}

+ (void)sortExistingGenreMutableArrayAlphabetically:(NSMutableArray **)anArray
{
    [*anArray sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

@end
