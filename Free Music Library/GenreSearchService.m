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
        NSMutableArray *levenshteinDistanceObjects = [NSMutableArray array];
        NSInteger thisDistance;
        LevenshteinDistanceItem *item;
        
        for(NSString *aGenreString in arrayOfGenreStrings){
            thisDistance = [aGenreString levenshteinDistanceToString:searchString];
            item = [[LevenshteinDistanceItem alloc] init];
            item.string = aGenreString;
            item.distance = thisDistance;
            [levenshteinDistanceObjects addObject: item];
        }
        //sort by distance (best match first in array), ascending order.
        [GenreSearchService sortLevenshteinDistanceResults:&levenshteinDistanceObjects];
        
        for(LevenshteinDistanceItem *item in levenshteinDistanceObjects){
            if(item.distance > 18)  //distance limit in final resutls
                break;
            if(resultArray.count == 50)  //limit on total # of results
                break;
            
            [resultArray addObject:item.string];
        }
        [resultArray removeObject:[GenreConstants noGenreSelectedGenreString]];
        
        //check for any 'special' genres that i want to map to specific search terms, even if they aren't very similar
        [GenreSearchService addAnySpecialSearchResultMapping:&resultArray currentSearchTerm:&searchString];
        
        [delegate genreSearchDidCompleteWithResults:resultArray];
    }
}

+ (void)setDelegate:(id<GenreSearchDelegate>)aDelegate
{
    delegate = aDelegate;
}

+ (void)sortLevenshteinDistanceResults:(NSMutableArray **)arrayOfLevenshteinDistanceItems
{
    NSSortDescriptor *highToLow = [NSSortDescriptor sortDescriptorWithKey:@"distance" ascending:YES];
    [*arrayOfLevenshteinDistanceItems sortUsingDescriptors:[NSArray arrayWithObject:highToLow]];
}

+ (void)addAnySpecialSearchResultMapping:(NSMutableArray **)arrayOfSearchResults currentSearchTerm:(NSString **)searchTerm
{
    NSArray *R_and_B = @[@"r and b", @"randb", @"r&b", @"r & b", @"r &b", @"r& b"];
    for(NSString *item in R_and_B){
        if([*searchTerm caseInsensitiveCompare:item] == NSOrderedSame){  //strings are exact match except possibly case
            int genreCodeFor_R_and_B_sould = 15;
            [*arrayOfSearchResults insertObject:[GenreConstants genreCodeToString:genreCodeFor_R_and_B_sould] atIndex:0];
            break;
        }
    }
}

@end
