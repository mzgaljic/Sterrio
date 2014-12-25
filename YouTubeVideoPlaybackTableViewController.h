//
//  YouTubeVideoPlaybackTableViewController.h
//  zTunes
//
//  Created by Mark Zgaljic on 8/7/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <XCDYouTubeKit/XCDYouTubeClient.h>
#import "YouTubeVideo.h"


@interface YouTubeVideoPlaybackTableViewController : UITableViewController <AVAudioSessionDelegate,
                                                                            AVAudioPlayerDelegate,
                                                                            UITextFieldDelegate,
                                                                            UINavigationControllerDelegate,
                                                                            UIActionSheetDelegate,
                                                                            UINavigationBarDelegate,
                                                                            UIImagePickerControllerDelegate>

@property (nonatomic, strong) YouTubeVideo *ytVideo;

- (id)initWithYouTubeVideo:(YouTubeVideo *)youtubeVideoObject;

- (void)addToLibraryButtonTapped;

@end
