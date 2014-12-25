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
    
    [UIView animateWithDuration:0.36f animations:^{
        if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
        {
            //entering view controller in landscape (fullscreen video)
            CGRect screenRect = [appWindow bounds];
            CGFloat screenWidth = screenRect.size.width;
            CGFloat screenHeight = screenRect.size.height;
            
            //+1 is because the view ALMOST covered the full screen.
            [playerView setFrame:CGRectMake(0, 0, screenWidth, ceil(screenHeight +1))];
            //hide status bar
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        }
        else
        {
            //show portrait player
            [playerView setFrame: [SongPlayerCoordinator bigPlayerFrameInPortrait]];
        }
    }];
    videoPlayerIsExpanded = YES;
}

- (void)beginShrinkingVideoPlayer
{
    if(videoPlayerIsExpanded == NO)
        return;
    
    PlayerView *videoPlayer = [MusicPlaybackController obtainRawPlayerView];
    
    [UIView animateWithDuration:0.6f animations:^{
        videoPlayer.frame = [SongPlayerCoordinator smallPlayerFrameInPortrait];
    }];
    videoPlayerIsExpanded = NO;
}

- (void)shrunkenVideoPlayerNeedsToBeRotated
{
    PlayerView *videoPlayer = [MusicPlaybackController obtainRawPlayerView];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
        //landscape rotation...
        [videoPlayer setFrame:[SongPlayerCoordinator smallPlayerFrameInLandscape]];
    else
        //portrait rotation...
        [videoPlayer setFrame:[SongPlayerCoordinator smallPlayerFrameInPortrait]];
}

+ (CGRect)smallPlayerFrameInPortrait
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    short padding = 10;
    short tabBarHeight = 49;
    int width = SMALL_VIDEO_WIDTH;
    int height = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:width];
    int x = window.frame.size.width - width - padding;
    int y = window.frame.size.height - tabBarHeight - height - padding;
    return CGRectMake(x, y, width, height);
}

+ (CGRect)smallPlayerFrameInLandscape
{
    UIWindow *appWindow = [UIApplication sharedApplication].keyWindow;
    short padding = 10;
    int width = SMALL_VIDEO_WIDTH;
    int height = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:width];
    int x = appWindow.frame.size.width - width - padding;
    int y = appWindow.frame.size.height - height - padding;
    return CGRectMake(x, y, width, height);
}

+ (CGRect)bigPlayerFrameInPortrait
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

@end
