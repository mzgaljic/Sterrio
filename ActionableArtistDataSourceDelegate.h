
//
//  ActionableArtistDataSourceDelegate.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/20/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Artist;
@protocol ActionableArtistDataSourceDelegate <NSObject>
@optional
- (void)performEditSegueWithArtist:(Artist *)artistToBeEdited;
- (void)performArtistDetailVCSegueWithArtist:(Artist *)anArtist;
- (void)userDidSelectArtistFromSinglePicker:(Artist *)chosenArtist;
@end
