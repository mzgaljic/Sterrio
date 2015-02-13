//
//  AppDelegate.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/20/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "AppDelegateSetupHelper.h"
#import "Song.h"
#import "Album.h"
#import "Artist.h"
#import "Playlist.h"
#import "GenreConstants.h"
#import "AlbumArtUtilities.h"
#import "SDWebImageManager.h"
#import "AppEnvironmentConstants.h"
#import "UIColor+LighterAndDarker.h"
#import "MusicPlaybackController.h"

#import "MainScreenViewController.h"
#import "MasterSongsTableViewController.h"
#import "MasterAlbumsTableViewController.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate, AVAudioSessionDelegate, AVAudioPlayerDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
