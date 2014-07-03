//
//  AppDelegate.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/20/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Song.h"
#import "Album.h"
#import "Artist.h"
#import "Playlist.h"
#import "GenreConstants.h"
#import "FileIOConstants.h"
#import "AlbumArtUtilities.h"
#import "ModelAlteredStatus.h"
#import "ModelAlteredStatus.h"
#import "AlteredModelSongQueue.h"
#import "AlteredModelAlbumQueue.h"
#import "AlteredModelArtistQueue.h"
#import "AppEnvironmentConstants.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
