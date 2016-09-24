//
//  IntroVideoView.m
//  Sterrio
//
//  Created by Mark Zgaljic on 12/20/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import "IntroVideoView.h"
#import "MZPlayer.h"
#import "SongPlayerViewDisplayUtility.h"
#import "AppEnvironmentConstants.h"
#import <CloudKit/CloudKit.h>
#import "PreferredFontSizeUtility.h"
#import "SSBouncyButton.h"
#import "ReachabilitySingleton.h"
#import "MRProgress.h"
#import "UIColor+LighterAndDarker.h"

@interface IntroVideoView ()
@property (nonatomic, strong) MZPlayer *player;
@property (nonatomic, strong) MZAppTheme *anAppTheme;
@property (nonatomic, strong) NSString *ckVideoRecordId;
@property (nonatomic, assign) CGRect playerRect;

@property (nonatomic, strong) SSBouncyButton *button;  //for retrying a download, etc.
@property (nonatomic, strong) UILabel *labelOnVideo;  //text ontop of the videos frame. An error msg or other msg.
@property (nonatomic, strong) NSURL *hardVideoUrl;  //google 'hard url' if confused.
@property (nonatomic, strong) UIView *placeholderVideoView;
@property (nonatomic, strong) MRProgressOverlayView *overlay;
@property (nonatomic, assign) BOOL playerInPlaybackBeforeGoingToBackground;
@property (nonatomic, assign) BOOL userIsWaitingForPlayback;
@end

@implementation IntroVideoView
static int const paddingFromScreenEdge = 18;

- (instancetype)initWithFrame:(CGRect)frame
                        title:(NSString *)title
                  description:(NSString *)desc
               introVideoRecordId:(NSString *)recordId
                   mzAppTheme:(MZAppTheme *)anAppTheme
{
    if(self = [super initWithFrame:frame]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appReturningToForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidGoToBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        _anAppTheme = anAppTheme;
        _ckVideoRecordId = recordId;
        
        int width = self.frame.size.width;
        int height = self.frame.size.height;
        int playerWidth = width - paddingFromScreenEdge;
        int playerHeight = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:playerWidth];
        _playerRect = CGRectMake((width - playerWidth)/2,
                                floor((height/2) - (playerHeight / 1.5)),
                                playerWidth,
                                playerHeight);
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _placeholderVideoView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        _placeholderVideoView.frame = _playerRect;
        _placeholderVideoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_placeholderVideoView];
        
        [self helpSetupViewTitle:title];
        [self helpSetupViewDescription:desc];
        
        if([[ReachabilitySingleton sharedInstance] isConnectedToWifi]) {
            [self loadAndPlayVideoOnLoad:@NO];
        } else if([[ReachabilitySingleton sharedInstance] isConnectedToCellular]) {
            NSString *msg = @"You're currently on a cellular connection.";
            [self displayTextOnVideoAreaWithText:msg buttonText:@"Download Video"];
        } else {
            NSString *msg = @"Cannot connect to the internet.";
            [self displayTextOnVideoAreaWithText:msg buttonText:@"Try downloading again"];
        }
    }
    return self;
}

- (void)helpSetupViewTitle:(NSString *)titleText
{
    int width = self.frame.size.width;
    int labelHeight = 45;
    int labelY = (_playerRect.origin.y / 2) - (labelHeight / 2);
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(paddingFromScreenEdge,
                                                               labelY,
                                                               width - (paddingFromScreenEdge * 2),
                                                               labelHeight)];
    title.text = titleText;
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                 size:28];
    title.textColor = _anAppTheme.navBarToolbarTextTint;
    [self addSubview:title];
}

- (void)helpSetupViewDescription:(NSString *)description
{
    int width = self.frame.size.width;
    int height = self.frame.size.height;
    int labelHeight = height / 4;
    int labelY = _playerRect.origin.y + _playerRect.size.height + 20;
    UILabel *desc = [[UILabel alloc] initWithFrame:CGRectMake(paddingFromScreenEdge,
                                                              labelY,
                                                              width - (paddingFromScreenEdge * 2),
                                                              labelHeight)];
    desc.text = description;
    desc.numberOfLines = 0;
    desc.textAlignment = NSTextAlignmentCenter;
    desc.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                size:18];
    desc.textColor = _anAppTheme.navBarToolbarTextTint;
    [self addSubview:desc];
}

- (void)helpSetupVideoPlayerWithUrl:(NSURL *)url beginPlayback:(BOOL)play
{
    CGRect playerFrame = CGRectMake(0, 0, _playerRect.size.width, _playerRect.size.height);
    _player = [[MZPlayer alloc] initWithFrame:playerFrame
                                     videoURL:url
                           useControlsOverlay:NO];
    _player.loopPlaybackForever = YES;
    _player.alpha = 0;
    [_placeholderVideoView addSubview:self.player];
    [UIView animateWithDuration:1.5
                          delay:0
         usingSpringWithDamping:0.85
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         _player.alpha = 1;
                     }
                     completion:nil];
    if(_userIsWaitingForPlayback || play) {
        [_player play];
    }
}

- (void)startVideoLooping
{
    [self.player play];
    _userIsWaitingForPlayback = YES;
}

- (void)stopPlaybackAndResetToBeginning
{
    _userIsWaitingForPlayback = NO;
    if(self.player != nil) {
        [self.player pause];
        //reset beginning
        Float64 beginning = 0.00;
        CMTime targetTime = CMTimeMakeWithSeconds(beginning, NSEC_PER_SEC);
        [self.player.avPlayer seekToTime:targetTime
                         toleranceBefore:kCMTimeZero
                          toleranceAfter:kCMTimeZero];
    }
}

+ (int)descriptionYValueForViewSize:(CGSize)size
{
    int width = size.width;
    int height = size.height;
    int playerWidth = width - paddingFromScreenEdge;
    int playerHeight = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:playerWidth];
    int playerY = (height/2) - (playerHeight / 1.5);
    int labelY = playerY + playerHeight + 20;
    return labelY;
}

- (void)displayTextOnVideoAreaWithText:(NSString *)text buttonText:(NSString *)buttonText
{
    _labelOnVideo = [self createVideoLabelText:text];
    if(buttonText == nil) {
        _button = nil;
    } else {
        _button = [[SSBouncyButton alloc] init];
        [_button setTitle:buttonText forState:UIControlStateNormal];
        _button.tintColor = [_anAppTheme.mainGuiTint lighterColor];
        _button.alpha = 0;
        _button.titleLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                  size:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
        [_button sizeToFit];
        short height = 36;
        short width = _button.frame.size.width + 8;  //sizeToFit squishes the width too much
        _button.frame = CGRectMake((_placeholderVideoView.frame.size.width/2) - (width/2),
                                   _labelOnVideo.frame.origin.y + _labelOnVideo.frame.size.height + 30,
                                   width,
                                   height);
        //when button isn't rendered, the text is centered in the video placeholder. Since the button
        //is being rendered, offset it so that they are both nicely centered.
        _labelOnVideo.frame = CGRectOffset(_labelOnVideo.frame, 0, -(height/2));

        [_button addTarget:self
                    action:@selector(loadAndPlayVideoOnLoadWithDelay)
          forControlEvents:UIControlEventTouchUpInside];
    }
    [_placeholderVideoView addSubview:_labelOnVideo];
    [_placeholderVideoView addSubview:_button];
    [UIView animateWithDuration:2
                          delay:0
         usingSpringWithDamping:0.85
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         _labelOnVideo.alpha = 1;
                         _button.alpha = 1;
                     }
                     completion:nil];
}

- (UILabel *)createVideoLabelText:(NSString *)text
{
    UILabel *label = [[UILabel alloc] initWithFrame:_placeholderVideoView.frame];
    label.text = text;
    label.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                 size:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin   |
                              UIViewAutoresizingFlexibleRightMargin  |
                              UIViewAutoresizingFlexibleTopMargin    |
                              UIViewAutoresizingFlexibleBottomMargin);
    CGRect rect = _placeholderVideoView.frame;
    [label sizeToFit];
    label.frame = CGRectMake((rect.size.width/2) - (label.frame.size.width/2),
                             (rect.size.height/2) - (label.frame.size.height/2),
                             label.frame.size.width,
                             label.frame.size.height);
    label.textColor = [UIColor whiteColor];
    label.alpha = 0;
    return label;
}

- (void)loadAndPlayVideoOnLoadWithDelay
{
    //called when the button is tapped so that the tap animaton can finish before the action happens.
    [self performSelector:@selector(loadAndPlayVideoOnLoad:)
               withObject:@YES
               afterDelay:0.75];
}

/**
 Will start video playback if the CloudKit asset download succeeds. Otherwise, an error message with a
 'retry' button is presented to the user.
 */
- (void)loadAndPlayVideoOnLoad:(NSNumber *)playOnLoad
{
    __block BOOL shouldPlayOnLoad = [playOnLoad boolValue];
    [UIView animateWithDuration:0.70
                          delay:0
         usingSpringWithDamping:0.85
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         _button.alpha = 0;
                         _labelOnVideo.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [_button removeFromSuperview];
                         _button = nil;
                         [_labelOnVideo removeFromSuperview];
                         _labelOnVideo = nil;
                     }];
    _overlay = [MRProgressOverlayView showOverlayAddedTo:_placeholderVideoView
                                                   title:@""
                                                    mode:MRProgressOverlayViewModeDeterminateHorizontalBar
                                                animated:YES];
    CKDatabase *publicDB = [[CKContainer defaultContainer] publicCloudDatabase];
    __block CKRecordID *recordId = [[CKRecordID alloc] initWithRecordName:_ckVideoRecordId];
    CKFetchRecordsOperation *fetchOperation = [[CKFetchRecordsOperation alloc] initWithRecordIDs:@[recordId]];
    
    __weak IntroVideoView *weakself = self;
    fetchOperation.perRecordProgressBlock = ^(CKRecordID *recordId, double progress) {
        safeSynchronousDispatchToMainQueue(^{
            weakself.overlay.progress = progress;
        });
    };
    fetchOperation.fetchRecordsCompletionBlock = ^(NSDictionary *recordsByRecordID, NSError *opError) {
        safeSynchronousDispatchToMainQueue(^{
            if(opError) {
                NSString *errorMSg = @"A problem occurred loading the video.";
                [weakself displayTextOnVideoAreaWithText:errorMSg buttonText:@"Retry download"];
            } else {
                NSArray *records = [recordsByRecordID allValues];
                NSAssert(records.count == 1, @"'successful' record count returned does not match 1!");
                CKRecord *record = records[0];
                CKAsset *videoAsset = record[@"data"];
                if(videoAsset.fileURL != nil) {
                    NSURL *usableUrl = nil;
                    NSString *videoExtension = record[@"fileExtension"];
                    weakself.hardVideoUrl = [IntroVideoView createHardLinkToCKAssetUrl:videoAsset.fileURL
                                                                             extension:videoExtension];
                    usableUrl = weakself.hardVideoUrl;
                    if(usableUrl == nil) {
                        usableUrl = [IntroVideoView createCopyOfCkAssetAtUrl:videoAsset.fileURL
                                                                addExtension:videoExtension];
                    }
                    [weakself helpSetupVideoPlayerWithUrl:usableUrl beginPlayback:shouldPlayOnLoad];
                }
            }
            [weakself.overlay dismiss:YES];
            weakself.overlay = nil;
        });
    };
    [publicDB addOperation:fetchOperation];
}

+ (NSURL *)createCopyOfCkAssetAtUrl:(NSURL *)url addExtension:(NSString *)extension
{
    NSString *destPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[url lastPathComponent]];
    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:url.absoluteString toPath:destPath error:&error];
    if(error) {
        return nil;
    }
    return [NSURL URLWithString:destPath];
}

+ (NSURL *)createHardLinkToCKAssetUrl:(NSURL *)url extension:(NSString *)extension {
    NSError *err;
    if([url.absoluteString hasSuffix:extension]) {
        extension = @"";
    }
    NSURL *hardUrl = [IntroVideoView generateHardUrlPathToCloudkitAssetUrl:url extension:extension];
    if (![hardUrl checkResourceIsReachableAndReturnError:nil]) {
        if (![[NSFileManager defaultManager] linkItemAtURL:url toURL:hardUrl error:&err]) {
            return nil;  //creating hard link failed.
        }
    }
    return hardUrl;
}

+ (BOOL)removeHardUrl:(NSURL *)hardUrl {
    NSError *err;
    if ([hardUrl checkResourceIsReachableAndReturnError:nil]) {
        return [[NSFileManager defaultManager] removeItemAtURL:hardUrl error:&err];
    }
    return YES;
}

/**
 extension parameter should not contain a period.
 */
+ (NSURL *)generateHardUrlPathToCloudkitAssetUrl:(NSURL *)aUrl extension:(NSString *)extension {
    return [aUrl URLByAppendingPathExtension:extension];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [IntroVideoView removeHardUrl:_hardVideoUrl];
    [_player destroyPlayer];
    _player = nil;
    _anAppTheme = nil;
    _ckVideoRecordId = nil;
    _button = nil;
    _labelOnVideo = nil;
    _hardVideoUrl = nil;
    _placeholderVideoView = nil;
    _overlay = nil;
}

- (void)appReturningToForeground
{
    [self.player reattachLayerWithPlayer];
    if(_playerInPlaybackBeforeGoingToBackground) {
        [self.player play];
    }
}

- (void)appDidGoToBackground
{
    [self.player removePlayerFromLayer];
    if(self.player) {
        _playerInPlaybackBeforeGoingToBackground = self.player.isPlaying;
    }
    [self.player pause];
}

@end
