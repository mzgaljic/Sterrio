//
//  PlaybackHistory.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/15/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"

@interface PlaybackHistory : NSObject

+ (NSArray *)listOfRecentlyPlayedSongs;
+ (void)addSongToHistory:(Song *)playedSong;

@end
