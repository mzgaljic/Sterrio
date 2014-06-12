//
//  SyncedSQLMusicModelUtility.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/5/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLiteManager.h"

@interface SyncedSQLMusicModelUtility : NSObject
extern const int ALBUMS;
extern const int ARTISTS;
extern const int PLAYLISTS;
extern const int PLAYLIST_SONGS;
extern const int SONGS;

+ (BOOL)initAllModels;

@end
