//
//  PlayableDataSearchDataSource.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/16/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayableDataSearchDataSourceDelegate.h"
#import "SearchBarDataSourceDelegate.h"

//IMPORTANT: this class will only function properly if used with a subclass of PlayableBaseDataSource.

@class MySearchBar;
@interface PlayableDataSearchDataSource : NSObject <UISearchBarDelegate>

- (instancetype)initWithTableView:(UITableView *)tableView playableDataSearchDataSourceDelegate:(id<PlayableDataSearchDataSourceDelegate>)delegate1
      searchBarDataSourceDelegate:(id <SearchBarDataSourceDelegate>)delegate2;

- (void)displayEmptyTableUserMessageWithText:(NSString *)text;
- (void)removeEmptyTableUserMessage;

- (MySearchBar *)setUpSearchBar;
//- (void)prepareForDealloc;

@end
