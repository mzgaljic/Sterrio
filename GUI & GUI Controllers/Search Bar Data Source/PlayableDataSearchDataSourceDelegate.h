
//
//  PlayableDataSearchDataSourceDelegate.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/16/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NSFetchRequest;
@class NSString;

//The subclasses of PlayableBaseDataSource should conform to this protocol.
@protocol PlayableDataSearchDataSourceDelegate <NSObject>
- (NSFetchRequest *)fetchRequestForSearchBarQuery:(NSString *)query;
- (void)searchResultsShouldBeDisplayed:(BOOL)displaySearchResults;
- (void)searchResultsFromUsersQuery:(NSArray *)modelObjects;
- (NSUInteger)playableDataSourceEntireModelCount;  //ie: total number of songs, or albums, etc.
@end
