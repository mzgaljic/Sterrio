//
//  PlayableBaseDataSource.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/26/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIImage+colorImages.h"
#import "UIColor+LighterAndDarker.h"
#import <FXImageView/UIImage+FX.h>
#import "MSCellAccessory.h"
#import "MGSwipeButton.h"
#import "MGSwipeTableCell.h"
#import "SearchBarDataSourceDelegate.h"
#import "PlayableDataSearchDataSource.h"
#import "KnownEnums.h"


@class MySearchBar;
@interface PlayableBaseDataSource : NSObject <UISearchBarDelegate>

@property (nonatomic, assign) BOOL displaySearchResults;
@property (nonatomic, assign) id <SearchBarDataSourceDelegate> searchBarDataSourceDelegate;
@property (nonatomic, strong) NSString *emptyTableUserMessage;


- (UIColor *)colorForNowPlayingItem;
- (MySearchBar *)setUpSearchBar;
- (NSIndexPath *)indexPathInSearchTableForObject:(id)someObject;

//Boring utility methods for subclasses
- (UIViewController *)topViewController;
- (UIViewController *)topViewController:(UIViewController *)rootViewController;
@end

