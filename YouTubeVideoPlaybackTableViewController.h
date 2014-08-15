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

#import "Song.h"
#import "Album.h"

#import "Reachability.h"
#import "SDWebImageManager.h"
#import "YouTubeVideo.h"
#import "SDCAlertView.h"
#import "AppEnvironmentConstants.h"
#import "PreferredFontSizeUtility.h"
#import "YouTubeMoviePlayerSingleton.h"
#import "NSString+WhiteSpace_Utility.h"
#import "AlbumArtUtilities.h"
#import "UIImage+colorImages.h"
#import "MRProgress.h"
#import "DZNPhotoPickerController.h"
#import "UIImagePickerControllerExtended.h"
#import "NSString+HTTP_Char_Escape.h"

@interface YouTubeVideoPlaybackTableViewController : UITableViewController <AVAudioSessionDelegate,
                                                                            AVAudioPlayerDelegate,
                                                                            UITextFieldDelegate,
                                                                            UINavigationControllerDelegate,
                                                                            UIActionSheetDelegate,
                                                                            ALMoviePlayerControllerDelegate,
                                                                            UINavigationBarDelegate,
                                                                            UIImagePickerControllerDelegate>

@property (nonatomic, strong) YouTubeVideo *ytVideo;

- (id)initWithYouTubeVideo:(YouTubeVideo *)youtubeVideoObject;

- (void)addToLibraryButtonTapped;

@end
