//
//  YouTubeSongAdderViewController.h
//  Muzic
//
//  Created by Mark Zgaljic on 1/4/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MyViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <XCDYouTubeKit/XCDYouTubeClient.h>
#import "XCDYouTubeVideoPlayerViewController.h"
#import "YouTubeVideo.h"
#import "Reachability.h"
#import "MusicPlaybackController.h"
#import "MyAlerts.h"
#import "SongPlayerViewDisplayUtility.h"
#import "SDWebImageManager.h"
#import "YouTubeVideoDetailLookupDelegate.h"
#import "UIImage+colorImages.h"
#import "UIColor+LighterAndDarker.h"
#import "MZSongModifierTableView.h"
#import "MZSongModifierDelegate.h"

@interface YouTubeSongAdderViewController : MyViewController <YouTubeVideoDetailLookupDelegate,
                                                            MZSongModifierDelegate>

- (id)initWithYouTubeVideo:(YouTubeVideo *)youtubeVideoObject;

@end
