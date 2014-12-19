//
//  SongPlayerViewController.h
//  Muzic
//
//  Created by Mark Zgaljic on 10/18/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>  //needed for avplayer
#import "Artist.h"
#import "Album.h"
#import <MediaPlayer/MediaPlayer.h>  //needed for placing info/media on lock screen
#import "PlayerView.h"  //custom avplayer view
#import "ASValueTrackingSlider.h"  //slider
#import "PreferredFontSizeUtility.h"
#import "MRProgress.h"  //loading spinner
#import "SDCAlertView.h"  //custom alert view
#import "UIButton+ExpandedHitArea.h"
#import "MusicPlaybackController.h"  //controls queue playback
#import "Reachability.h"  //checking internet connectivity
#import "NSNull+AVPlayer.h"  //dealing with key value observer 'NSNull' issues
#import "UIImage+colorImages.h"  //for recoloring png images
#import "UIColor+LighterAndDarker.h"  //creating lighter and darker colors from base colors
#import "UIColor+SystemTintColor.h"
#import "AlbumArtUtilities.h"  //interface for accessing album art on disk
#import "SongPlayerViewDisplayHelper.h"  //gui code helpers (determining aspect ration player size, etc)


NSString * const PAUSE_IMAGE_FILLED = @"Pause-Filled";
NSString * const PAUSE_IMAGE_UNFILLED = @"Pause-Line";
NSString * const PLAY_IMAGE_FILLED = @"Play-Filled";
NSString * const PLAY_IMAGE_UNFILLED = @"Play-Line";
NSString * const FORWARD_IMAGE_FILLED = @"Seek-Filled";
NSString * const FORWARD_IMAGE_UNFILLED = @"Seek-Line";
NSString * const BACKWARD_IMAGE_FILLED = @"Backward-Filled";
NSString * const BACKWARD_IMAGE_UNFILLED = @"Backward-Line";

void *kCurrentItemDidChangeKVO  = &kCurrentItemDidChangeKVO;
void *kRateDidChangeKVO         = &kRateDidChangeKVO;
void *kStatusDidChangeKVO       = &kStatusDidChangeKVO;
void *kDurationDidChangeKVO     = &kDurationDidChangeKVO;
void *kTimeRangesKVO            = &kTimeRangesKVO;
void *kBufferFullKVO            = &kBufferFullKVO;
void *kBufferEmptyKVO           = &kBufferEmptyKVO;
void *kDidFailKVO               = &kDidFailKVO;


@interface SongPlayerViewController : UIViewController <AVAudioSessionDelegate,
                                                        AVAudioPlayerDelegate,
                                                        ASValueTrackingSliderDataSource>

@property (weak, nonatomic) IBOutlet UINavigationItem *navBar;  //really the navBar title item
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *playbackTimeSlider;

@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalDurationLabel;

- (IBAction)playbackSliderValueHasChanged:(id)sender;
- (IBAction)playbackSliderEditingHasBegun:(id)sender;
- (IBAction)playbackSliderEditingHasEnded:(id)sender;

@end
