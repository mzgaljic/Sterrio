//
//  YouTubeSongAdderViewController.h
//  Muzic
//
//  Created by Mark Zgaljic on 1/4/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MyTableViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <XCDYouTubeKit/XCDYouTubeClient.h>
#import "XCDYouTubeVideoPlayerViewController.h"
#import "YouTubeVideo.h"
#import "Reachability.h"
#import "MusicPlaybackController.h"
#import "MyAlerts.h"
#import "SongPlayerViewDisplayUtility.h"
#import "SDWebImageManager.h"
#import "YouTubeVideoSearchDelegate.h"
#import "YouTubeVideoDurationLookupDelegate.h"

@interface YouTubeSongAdderViewController : MyTableViewController <YouTubeVideoDurationLookupDelegate>

- (id)initWithYouTubeVideo:(YouTubeVideo *)youtubeVideoObject;

@end
