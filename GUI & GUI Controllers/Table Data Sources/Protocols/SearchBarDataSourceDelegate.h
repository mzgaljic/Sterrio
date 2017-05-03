//
//  SearchBarDataSourceDelegate.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/15/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

//The view controllers that would like to respond to the search bar
//state should conform to this protocol.
@protocol SearchBarDataSourceDelegate <NSObject>
- (void)searchBarIsBecomingActive;
- (void)searchBarIsBecomingInactive;
- (NSString *)placeholderTextForSearchBar;
@end