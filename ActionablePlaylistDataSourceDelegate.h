//
//  ActionablePlaylistDataSourceDelegate.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/3/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Playlist;
@protocol ActionablePlaylistDataSourceDelegate <NSObject>
- (void)performPlaylistDetailVCSegueWithPlaylist:(Playlist *)aPlaylist;
@end
