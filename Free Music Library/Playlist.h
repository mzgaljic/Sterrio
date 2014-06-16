//
//  Playlist.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Playlist : NSObject <NSCoding>

@property(atomic, strong) NSString *playlistName;
@property(atomic, strong) NSMutableArray *songsInThisPlaylist;

+ (NSArray *)loadAll;
- (BOOL)save;

@end
