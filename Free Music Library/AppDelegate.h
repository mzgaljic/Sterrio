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
#import "pthread.h"

#import "AppDelegateSetupHelper.h"
#import "Song.h"
#import "Album.h"
#import "Artist.h"
#import "Playlist.h"
#import "AlbumArtUtilities.h"
#import "AppEnvironmentConstants.h"
#import "MusicPlaybackController.h"
#import "OperationQueuesSingeton.h"
#import "LQAlbumArtBackgroundUpdater.h"

#import "MainScreenViewController.h"
#import "MasterSongsTableViewController.h"
#import "MasterAlbumsTableViewController.h"
#import "MasterArtistsTableViewController.h"
#import "MasterPlaylistTableViewController.h"

//crash reporting framework
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>


@interface AppDelegate : UIResponder <UIApplicationDelegate,
                                        AVAudioSessionDelegate,
                                        AVAudioPlayerDelegate>

@property (strong, nonatomic) UIWindow *window;

//used to make it appear as if the playerlayer is still attached to the player in backgrounded mode.
@property (strong, nonatomic) UIView *playerSnapshot;

- (void)restoreMainWindow;

@end
