//
//  ExistingEntityPickerDelegate.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/20/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Album;
@class Artist;
@protocol ExistingEntityPickerDelegate <NSObject>
@optional
- (void)existingAlbumHasBeenChosen:(Album *)album;
- (void)existingArtistHasBeenChosen:(Artist *)artist;
@end
