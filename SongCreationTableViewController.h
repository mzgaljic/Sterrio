//
//  SongCreationTableViewController.h
//  zTunes
//
//  Created by Mark Zgaljic on 8/4/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YouTubeVideo.h"
#import "SDWebImageManager.h"
#import "AppEnvironmentConstants.h"
#import "UIImage+ColoringExistingImage.h"

@interface SongCreationTableViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, strong) YouTubeVideo *selectedVideo;

- (id) initWithYouTubeVideo:(YouTubeVideo *)aYouTubeVideoObject;

@end
