//
//  SongPlayerCoordinator.m
//  Muzic
//
//  Created by Mark Zgaljic on 12/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "SongPlayerCoordinator.h"

@interface SongPlayerCoordinator ()
{
    BOOL videoPlayerIsExpanded;
    BOOL canIgnoreToolbar;  //navigation controller toolbar
    CGRect currentPlayerFrame;
}
@end

@implementation SongPlayerCoordinator
@synthesize delegate = _delegate;

static const short SMALL_VIDEO_WIDTH = 200;

#pragma mark - Class lifecycle stuff
+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    if([super init]){
        UIWindow *appWindow = [UIApplication sharedApplication].keyWindow;
        if([MusicPlaybackController obtainRawPlayerView].frame.size.width == [appWindow bounds].size.width)
            videoPlayerIsExpanded = YES;
        else
            videoPlayerIsExpanded = NO;
        canIgnoreToolbar = YES;
    }
    return self;
}

- (void)dealloc
{
    //singleton should never be released
    abort();
}

#pragma mark - Other
- (void)setDelegate:(id<VideoPlayerControlInterfaceDelegate>)theDelegate
{
    _delegate = theDelegate;
}

- (BOOL)isVideoPlayerExpanded
{
    return videoPlayerIsExpanded;
}

- (void)begingExpandingVideoPlayer
{
    //toOrientation code from songPlayerViewController was removed here (code copied)
    if(videoPlayerIsExpanded == YES)
        return;
    
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    UIWindow *appWindow = [UIApplication sharedApplication].keyWindow;
    
    if(playerView == nil){
        //player not even on screen yet
        playerView = [[PlayerView alloc] init];
        player = [[MyAVPlayer alloc] init];
        [playerView setPlayer:player];  //attaches AVPlayer to AVPlayerLayer
        [MusicPlaybackController setRawAVPlayer:player];
        [MusicPlaybackController setRawPlayerView:playerView];
        [playerView setBackgroundColor:[UIColor blackColor]];
        [appWindow addSubview:playerView];
        //setting a temp frame in the bottom right corner for now
        [playerView setFrame:CGRectMake(appWindow.frame.size.width, appWindow.frame.size.height, 1, 1)];
        //real playerView frame set below...
    }
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    [UIView animateWithDuration:0.405f animations:^{
        if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
        {
            //entering view controller in landscape (fullscreen video)
            CGRect screenRect = [appWindow bounds];
            CGFloat screenWidth = screenRect.size.width;
            CGFloat screenHeight = screenRect.size.height;
            
            //+1 is because the view ALMOST covered the full screen.
            currentPlayerFrame = CGRectMake(0, 0, screenWidth, ceil(screenHeight +1));
            [playerView setFrame:currentPlayerFrame];
            //hide status bar
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        }
        else
        {
            //show portrait player
            currentPlayerFrame = [self bigPlayerFrameInPortrait];
            [playerView setFrame: currentPlayerFrame];
        }
    } completion:^(BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //make spinner redraw itself
            [[MRProgressOverlayView overlayForView:[MusicPlaybackController obtainRawPlayerView]] manualLayoutSubviews];
        });
    }];
    videoPlayerIsExpanded = YES;
}

- (void)beginShrinkingVideoPlayer
{
    if(videoPlayerIsExpanded == NO)
        return;
    
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    __weak SongPlayerCoordinator *weakSelf = self;
    BOOL needLandscapeFrame = YES;
    if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)
        needLandscapeFrame = NO;
    [UIView animateWithDuration:0.7f animations:^{
        if(needLandscapeFrame)
            currentPlayerFrame = [weakSelf smallPlayerFrameInLandscape];
        else
            currentPlayerFrame = [weakSelf smallPlayerFrameInPortrait];
        playerView.frame = currentPlayerFrame;
    } completion:^(BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //make spinner redraw itself
            [[MRProgressOverlayView overlayForView:[MusicPlaybackController obtainRawPlayerView]] manualLayoutSubviews];
        });
    }];
    videoPlayerIsExpanded = NO;
}

- (void)shrunkenVideoPlayerNeedsToBeRotated
{
    PlayerView *videoPlayer = [MusicPlaybackController obtainRawPlayerView];
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
        //landscape rotation...
        currentPlayerFrame = [self smallPlayerFrameInLandscape];
    else
        //portrait rotation...
        currentPlayerFrame = [self smallPlayerFrameInPortrait];
    [videoPlayer setFrame:currentPlayerFrame];
}

- (void)shrunkenVideoPlayerShouldRespectToolbar
{
    canIgnoreToolbar = NO;
    //need to re-animate playerView into a new position
    
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        //landscape rotation...
        [UIView animateWithDuration:0.6f animations:^{
            currentPlayerFrame = [self smallPlayerFrameInLandscape];
            playerView.frame = currentPlayerFrame;
        } completion:^(BOOL finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //make spinner redraw itself
                [[MRProgressOverlayView overlayForView:[MusicPlaybackController obtainRawPlayerView]] manualLayoutSubviews];
            });
        }];
    } else{
        //portrait
        [UIView animateWithDuration:0.6f animations:^{
            currentPlayerFrame = [self smallPlayerFrameInPortrait];
            playerView.frame = currentPlayerFrame;
        } completion:^(BOOL finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //make spinner redraw itself
                [[MRProgressOverlayView overlayForView:[MusicPlaybackController obtainRawPlayerView]] manualLayoutSubviews];
            });
        }];
    }
}

- (void)shrunkenVideoPlayerCanIgnoreToolbar
{
    canIgnoreToolbar = YES;
    //need to re-animate playerView into new position
    
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        //landscape rotation...
        [UIView animateWithDuration:0.6f animations:^{
            currentPlayerFrame = [self smallPlayerFrameInLandscape];
            playerView.frame = currentPlayerFrame;
        } completion:^(BOOL finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //make spinner redraw itself
                [[MRProgressOverlayView overlayForView:[MusicPlaybackController obtainRawPlayerView]] manualLayoutSubviews];
            });
        }];
    } else{
        //portrait
        [UIView animateWithDuration:0.6f animations:^{
            currentPlayerFrame = [self smallPlayerFrameInPortrait];
            playerView.frame = currentPlayerFrame;
        } completion:^(BOOL finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //make spinner redraw itself
                [[MRProgressOverlayView overlayForView:[MusicPlaybackController obtainRawPlayerView]] manualLayoutSubviews];
            });
        }];
    }
}

- (CGRect)smallPlayerFrameInPortrait
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    short padding = 10;
    short tabBarHeight = 49;
    short toolbarHeight = 44;
    int width, height, x, y;
    
    //set frame based on what kind of VC we are over at the moment
    if(canIgnoreToolbar){
        width = SMALL_VIDEO_WIDTH;
        height = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:width];
        x = window.frame.size.width - width - padding;
        y = window.frame.size.height - tabBarHeight - height - padding;
    } else{
        width = SMALL_VIDEO_WIDTH - 70;
        height = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:width];
        x = window.frame.size.width - width - padding;
        y = window.frame.size.height - toolbarHeight - height - padding;
    }

    return CGRectMake(x, y, width, height);
}

- (CGRect)smallPlayerFrameInLandscape
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    short padding = 10;
    short toolbarHeight = 34;
    int width, height, x, y;
    
    //set frame based on what kind of VC we are over at the moment
    if(canIgnoreToolbar){
        width = SMALL_VIDEO_WIDTH;
        height = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:width];
        x = window.frame.size.width - width - padding;
        y = window.frame.size.height - height - padding;
    } else{
        width = SMALL_VIDEO_WIDTH - 70;
        height = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:width];
        x = window.frame.size.width - width - padding;
        y = window.frame.size.height - toolbarHeight - height - padding;
    }
    
    return CGRectMake(x, y, width, height);
}

- (CGRect)bigPlayerFrameInPortrait
{
    CGPoint screenWidthAndHeight = [SongPlayerCoordinator widthAndHeightOfScreen];
    float videoFrameHeight = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:screenWidthAndHeight.x];
    float playerFrameYTempalue = roundf(((screenWidthAndHeight.y / 2.0) /1.5));
    int playerYValue = nearestEvenInt((int)playerFrameYTempalue);
    return CGRectMake(0, playerYValue, screenWidthAndHeight.x, videoFrameHeight);
}

+ (CGPoint)widthAndHeightOfScreen
{
    UIWindow *appWindow = [UIApplication sharedApplication].keyWindow;
    float widthOfScreenRoationIndependant;
    float heightOfScreenRotationIndependant;
    float  a = [appWindow bounds].size.height;
    float b = [appWindow bounds].size.width;
    if(a < b)
    {
        heightOfScreenRotationIndependant = b;
        widthOfScreenRoationIndependant = a;
    }
    else
    {
        widthOfScreenRoationIndependant = b;
        heightOfScreenRotationIndependant = a;
    }
    return CGPointMake(widthOfScreenRoationIndependant, heightOfScreenRotationIndependant);
}

- (void)temporarilyDisablePlayer
{
    __weak PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    [UIView animateWithDuration:1.0 animations:^{
        playerView.alpha = 0.25;
        playerView.userInteractionEnabled = NO;
    }];
}

- (void)enablePlayerAgain
{
    __weak PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    [UIView animateWithDuration:1.0 animations:^{
        playerView.alpha = 1.0;
        playerView.userInteractionEnabled = YES;
    }];
}

- (BOOL)isPlayerEnabled
{
    return ([MusicPlaybackController obtainRawPlayerView].alpha == 1) ? YES : NO;
}

- (CGRect)currentPlayerViewFrame
{
    return currentPlayerFrame;
}

- (void)recordCurrentPlayerViewFrame:(CGRect)newFrame
{
    currentPlayerFrame = newFrame;
}

@end
