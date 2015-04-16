//
//  PlaylistSongAdderDataSourceDelegate.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/15/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KnownEnums.h"

@protocol PlaylistSongAdderDataSourceDelegate <NSObject>
- (void)setSuccessNavBarButtonStringValue:(NSString *)newValue;
- (PLAYLIST_STATUS)currentPlaylistStatus;
- (NSOrderedSet *)existingPlaylistSongs;
@end