//
//  ActionableAlbumDataSourceDelegate.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/16/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Album;
@protocol ActionableAlbumDataSourceDelegate <NSObject>
@optional
- (void)performEditSegueWithAlbum:(Album *)albumToBeEdited;
- (void)performAlbumDetailVCSegueWithAlbum:(Album *)anAlbum;
- (void)userDidSelectAlbumFromSinglePicker:(Album *)chosenAlbum;
@end