//
//  SongPlayerViewController.h
//  Muzic
//
//  Created by Mark Zgaljic on 10/18/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#include <math.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>  //needed for avplayer
#import "Artist.h"
#import "Album.h"
#import "PlayerView.h"  //custom avplayer view
#import "PreferredFontSizeUtility.h"
#import "MRProgress.h"
#import "SDCAlertView.h"  //custom alert view
#import "UIButton+ExpandedHitArea.h"
#import "MusicPlaybackController.h"  //controls queue playback
#import "Reachability.h"  //checking internet connectivity
#import "NSNull+AVPlayer.h"  //dealing with key value observer 'NSNull' issues
#import "UIImage+colorImages.h"  //for recoloring png images
#import "UIColor+LighterAndDarker.h"  //creating lighter and darker colors from base colors
#import "AlbumArtUtilities.h"  //interface for accessing album art on disk
#import "SongPlayerCoordinator.h"  //controls the video player frame and responds to player events via delegates
#import "SongPlayerNavController.h"
#import "MyAlerts.h"
#import "MyViewController.h"
#import "TOMSMorphingLabel.h"
#import "JAMAccurateSlider.h"
#import <GCDiscreetNotificationView.h>
#import "ReachabilitySingleton.h"
#import "VideoPlayerControlInterfaceDelegate.h"
#import "QueueViewController.h"
#import "AFBlurSegue.h"
#import "ActionSheetDatePicker.h"
#import "SSBouncyButton.h"
#import "IBActionSheet.h"

//for the playback timer
#import "pthread.h"


@class MusicPlaybackController;


@interface SongPlayerViewController : MyViewController <AVAudioSessionDelegate,
                                                        AVAudioPlayerDelegate,
                                                        VideoPlayerControlInterfaceDelegate,
                                                        UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UINavigationItem *navBar;  //really the navBar title item

@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalDurationLabel;
@property (weak, nonatomic) IBOutlet MarqueeLabel *songNameLabel;
@property (weak, nonatomic) IBOutlet MarqueeLabel *artistAndAlbumLabel;
@property (weak, nonatomic) IBOutlet JAMAccurateSlider *playbackSlider;
@property (weak, nonatomic) IBOutlet UIView *sliderHintView;



- (IBAction)playbackSliderValueHasChanged:(id)sender;
- (IBAction)playbackSliderEditingHasBegun:(id)sender;
- (IBAction)playbackSliderEditingHasEndedA:(id)sender;  //touch up inside
- (IBAction)playbackSliderEditingHasEndedB:(id)sender;  //touch up outside

- (void)preDealloc;  //used by the PlayerView.h when it needs to pop this VC.

@end
