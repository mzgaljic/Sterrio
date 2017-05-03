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
    CGRect currentPlayerFrame;
    short SMALL_VIDEO_WIDTH;
    BOOL wasTabBarHiddenBeforePlayerExpansion;
}
@end

@implementation SongPlayerCoordinator
static BOOL isVideoPlayerExpanded;
static BOOL playerIsOnScreen = NO;
static BOOL playerIsInDisabledState = NO;
static BOOL isPlayerEnabled;
static BOOL canIgnoreToolbar = YES;
float const disabledPlayerAlpa = 0.20;
float const amountToShrinkSmallPlayerWhenRespectingToolbar = 35;

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
    if(self = [super init]){
        isPlayerEnabled = YES;
        UIWindow *appWindow = [UIApplication sharedApplication].keyWindow;
        if([MusicPlaybackController obtainRawPlayerView].frame.size.width == [appWindow bounds].size.width)
            isVideoPlayerExpanded = YES;
        else
            isVideoPlayerExpanded = NO;
        
        [self setSmallVideoWidth];
        wasTabBarHiddenBeforePlayerExpansion = NO;
    }
    return self;
}

- (void)dealloc
{
    //singleton should never be released
    abort();
}

#pragma mark - Other
+ (BOOL)isVideoPlayerExpanded
{
    return isVideoPlayerExpanded;
}

- (void)begingExpandingVideoPlayer
{
    //toOrientation code from songPlayerViewController was removed here (code copied)
    if(isVideoPlayerExpanded == YES)
        return;
    
    //I want this to be set "too early", just playing it safe.
    isVideoPlayerExpanded = YES;
    
    if([AppEnvironmentConstants isTabBarHidden])
        wasTabBarHiddenBeforePlayerExpansion = YES;
    else
        [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated object:[NSNumber numberWithBool:YES]];
    
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    UIWindow *appWindow = [UIApplication sharedApplication].keyWindow;
    
    if(playerView == nil){
        //player not even on screen yet
        playerView = [[PlayerView alloc] init];
        MyAVPlayer *player = [[MyAVPlayer alloc] init];
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
    
    [UIView animateWithDuration:0.70
                          delay:0
         usingSpringWithDamping:0.80f
          initialSpringVelocity:1
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
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
                         playerView.alpha = 1;  //in case player was killed.
                         
                         MRProgressOverlayView *view = (MRProgressOverlayView *)[MRProgressOverlayView overlayForView:playerView];
                         if([MusicPlaybackController isSpinnerForWifiNeededOnScreen])
                             view.titleLabelText = @"Song requires WiFi";
                         
                         [view manualLayoutSubviews];
                         CGPoint newCenter = [playerView convertPoint:playerView.center
                                                  fromCoordinateSpace:playerView.superview];
                         [playerView newAirplayInUseMsgCenter:newCenter];

                     } completion:nil];
}

- (void)beginShrinkingVideoPlayer
{
    if(isVideoPlayerExpanded == NO){
        return;
    }
    
    if(! wasTabBarHiddenBeforePlayerExpansion) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated object:@NO];
    }
    
    wasTabBarHiddenBeforePlayerExpansion = NO;
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    currentPlayerFrame = [self smallPlayerFrameBasedOnCurrentOrientation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MZExpandedPlayerIsShrinking object:nil];
    
    [UIView animateWithDuration:0.56f
                          delay:0
         usingSpringWithDamping:0.80f
          initialSpringVelocity:0.2f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         playerView.frame = currentPlayerFrame;
                         
                         MRProgressOverlayView *view = (MRProgressOverlayView *)[MRProgressOverlayView overlayForView:playerView];
                         if([MusicPlaybackController isSpinnerForWifiNeededOnScreen])
                             view.titleLabelText = @"WiFi";
                         [view manualLayoutSubviews];
                         CGPoint newCenter = [playerView convertPoint:playerView.center
                                                  fromCoordinateSpace:playerView.superview];
                         [playerView newAirplayInUseMsgCenter:newCenter];
                     } completion:^(BOOL finished) {
                         isVideoPlayerExpanded = NO;
                         [playerView shrunkenFrameHasChanged];
                     }];
}

- (void)beginAnimatingPlayerIntoMinimzedStateIfNotExpanded
{
    if(isVideoPlayerExpanded == YES)
        return;
    [SongPlayerCoordinator playerWasKilled:NO];
    [SongPlayerCoordinator placePlayerInDisabledState:NO];
    isVideoPlayerExpanded = NO;
    
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    UIWindow *appWindow = [UIApplication sharedApplication].keyWindow;
    
    if(playerView == nil){
        //player not even on screen yet
        playerView = [[PlayerView alloc] init];
        playerView.alpha = 0;
        MyAVPlayer *player = [[MyAVPlayer alloc] init];
        [playerView setPlayer:player];  //attaches AVPlayer to AVPlayerLayer
        playerView.alpha = 0;
        [MusicPlaybackController setRawAVPlayer:player];
        [MusicPlaybackController setRawPlayerView:playerView];
        [playerView setBackgroundColor:[UIColor blackColor]];
    }
    
    currentPlayerFrame = [self smallPlayerFrameBasedOnCurrentOrientation];
    playerView.frame = currentPlayerFrame;
    [appWindow addSubview:playerView];
    
    [UIView animateWithDuration:1
                          delay:0
         usingSpringWithDamping:0.85f
          initialSpringVelocity:1.0f
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         playerView.alpha = 1;
                     } completion:^(BOOL finished) {
                         [playerView shrunkenFrameHasChanged];
                     }];
}

static UIInterfaceOrientation orientationOnLastRotate;
- (void)shrunkenVideoPlayerNeedsToBeRotated
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if(! UIDeviceOrientationIsValidInterfaceOrientation(deviceOrientation))
        return;
    if([SongPlayerCoordinator isPlayerOnScreen])
    {
        UIInterfaceOrientation interfaceOrientation = [SongPlayerCoordinator convertDeviceOrientationToInferfaceOrientation:deviceOrientation];
        if(orientationOnLastRotate == interfaceOrientation)
            return;
        
        //dont mess with playerview in this orientation. we dont support it anyway.
        if(interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
            return;
        
        orientationOnLastRotate = interfaceOrientation;
        
        PlayerView *videoPlayer = [MusicPlaybackController obtainRawPlayerView];
        currentPlayerFrame = [self smallPlayerFrameBasedOnCurrentOrientation];
        
        int padding = MZSmallPlayerVideoFramePadding;
        CGRect tempBeginFrame = CGRectMake(currentPlayerFrame.origin.x + SMALL_VIDEO_WIDTH + padding,
                                           currentPlayerFrame.origin.y,
                                           currentPlayerFrame.size.width,
                                           currentPlayerFrame.size.height);
        
        [videoPlayer setFrame:currentPlayerFrame];
        CGPoint newCenter = [videoPlayer convertPoint:videoPlayer.center
                                  fromCoordinateSpace:videoPlayer.superview];
        [videoPlayer setFrame:tempBeginFrame];
        
        [UIView animateWithDuration:1
                              delay:0
             usingSpringWithDamping:0.74
              initialSpringVelocity:0.8
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             videoPlayer.frame = currentPlayerFrame;
                             [videoPlayer shrunkenFrameHasChanged];
                             [videoPlayer newAirplayInUseMsgCenter:newCenter];
                             
                        } completion:nil];
        
        UIImageView *swipeUpTipView = nil;
        if(! [AppEnvironmentConstants userSawExpandingPlayerTip]) {
            //tip is on screen now. Rotate the swipe-up tip with the player.
            UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
            NSArray *subviews = window.subviews;
            for(UIView *view in subviews) {
                if([view isMemberOfClass:[UIImageView class]]) {
                    //imageView with highest index is the tip view.
                    swipeUpTipView = (UIImageView *)view;
                    break;
                }
            }
        }
        if(swipeUpTipView) {
            swipeUpTipView.center = videoPlayer.center;
            swipeUpTipView.frame = CGRectMake(swipeUpTipView.frame.origin.x,
                                              swipeUpTipView.frame.origin.y - (videoPlayer.frame.size.height/2),
                                              swipeUpTipView.frame.size.width,
                                              swipeUpTipView.frame.size.height);
            swipeUpTipView.alpha = 0;
            [UIView animateWithDuration:0.8 animations:^{
                swipeUpTipView.alpha = 1;
            }];
        }
    }
}

- (void)shrunkenVideoPlayerShouldRespectToolbar
{
    canIgnoreToolbar = NO;
    //need to re-animate playerView into a new position
    
    //first check if it was killed...its an edge case
    if(![SongPlayerCoordinator isPlayerOnScreen])
        return;
    
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    currentPlayerFrame = [self smallPlayerFrameBasedOnCurrentOrientation];
    
    [UIView animateWithDuration:0.6f animations:^{
        playerView.frame = currentPlayerFrame;
        [[MRProgressOverlayView overlayForView:playerView] manualLayoutSubviews];
        
        CGPoint newCenter = [playerView convertPoint:playerView.center
                                     fromCoordinateSpace:playerView.superview];
        [playerView newAirplayInUseMsgCenter:newCenter];
    } completion:^(BOOL finished) {
        [playerView shrunkenFrameHasChanged];
    }];
}

- (void)shrunkenVideoPlayerCanIgnoreToolbar
{
    canIgnoreToolbar = YES;
    //need to re-animate playerView into new position
    
    //first check if it was killed...its an edge case
    if(![SongPlayerCoordinator isPlayerOnScreen])
        return;
    PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    currentPlayerFrame = [self smallPlayerFrameBasedOnCurrentOrientation];
    
    [UIView animateWithDuration:0.6f animations:^{
        playerView.frame = currentPlayerFrame;
        [[MRProgressOverlayView overlayForView:playerView] manualLayoutSubviews];
        
        CGPoint newCenter = [playerView convertPoint:playerView.center
                                     fromCoordinateSpace:playerView.superview];
        [playerView newAirplayInUseMsgCenter:newCenter];
    } completion:^(BOOL finished) {
        [playerView shrunkenFrameHasChanged];
    }];
}

- (CGRect)smallPlayerFrameBasedOnCurrentOrientation
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = [SongPlayerCoordinator convertDeviceOrientationToInferfaceOrientation:deviceOrientation];
    
    //need to manually check instead of using convenience methods UIInterfaceOrientationIsLandscape...etc.
    //this is because it checks based on the current INTERFACE orientation, not device orientation...
    //and the interface orientation changes with a delay after the device orientation.
    if(interfaceOrientation == UIInterfaceOrientationPortrait
       || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return [self smallPlayerFrameInPortrait];
    else
        return [self smallPlayerFrameInLandscape];
}

- (CGRect)smallPlayerFrameInPortrait
{
    short toolbarHeight = 44;
    int width, height, x, y;
    
    CGPoint screenSize = [SongPlayerCoordinator widthAndHeightOfScreen];
    int screenWidth = screenSize.x;
    int screenHeight = screenSize.y;
    
    //set frame based on what kind of mode the VC wants the player in.
    if(canIgnoreToolbar){
        int adBannerHeight = [AppEnvironmentConstants bannerAdHeight];
        width = SMALL_VIDEO_WIDTH;
        height = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:width];
        x = screenWidth - width - MZSmallPlayerVideoFramePadding;
        y = screenHeight - height - MZSmallPlayerVideoFramePadding - MZTabBarHeight - adBannerHeight;
    } else{
        width = SMALL_VIDEO_WIDTH - amountToShrinkSmallPlayerWhenRespectingToolbar;
        height = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:width];
        x = screenWidth - width - MZSmallPlayerVideoFramePadding;
        y = screenHeight - toolbarHeight - height - MZSmallPlayerVideoFramePadding;
    }

    return CGRectMake(x, y, width, height);
}

- (CGRect)smallPlayerFrameInLandscape
{
    short toolbarHeight = 34;
    int width, height, x, y;
    
    CGPoint screenSize = [SongPlayerCoordinator widthAndHeightOfScreen];
    int screenWidth = screenSize.x;
    int screenHeight = screenSize.y;
    
    //set frame based on what kind of VC we are over at the moment
    if(canIgnoreToolbar){
        int adBannerHeight = [AppEnvironmentConstants bannerAdHeight];
        width = SMALL_VIDEO_WIDTH;
        height = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:width];
        x = screenWidth - width - MZSmallPlayerVideoFramePadding;
        y = screenHeight - height - MZSmallPlayerVideoFramePadding - MZTabBarHeight - adBannerHeight;
    } else{
        width = SMALL_VIDEO_WIDTH - amountToShrinkSmallPlayerWhenRespectingToolbar;
        height = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:width];
        x = screenWidth - width - MZSmallPlayerVideoFramePadding;
        y = screenHeight - toolbarHeight - height - MZSmallPlayerVideoFramePadding;
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
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = [SongPlayerCoordinator convertDeviceOrientationToInferfaceOrientation:deviceOrientation];
    
    
    UIWindow *appWindow = [UIApplication sharedApplication].keyWindow;
    float widthOfScreen;
    float heightOfScreen;
    float  a = [appWindow bounds].size.height;
    float b = [appWindow bounds].size.width;
    if(a > b)
    {
        if(interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown
           || interfaceOrientation == UIInterfaceOrientationPortrait){
            heightOfScreen = a;
            widthOfScreen = b;
        } else{
            widthOfScreen = a;
            heightOfScreen = b;
        }
    }
    else
    {
        if(interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown
           || interfaceOrientation == UIInterfaceOrientationPortrait){
            heightOfScreen = b;
            widthOfScreen = a;
        } else{
            widthOfScreen = b;
            heightOfScreen = a;
        }
    }
    
    return CGPointMake(widthOfScreen, heightOfScreen);
}

- (void)temporarilyDisablePlayer
{
    isPlayerEnabled = NO;
    __weak PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    [UIView animateWithDuration:1.0 animations:^{
        playerView.alpha = disabledPlayerAlpa;
        playerView.userInteractionEnabled = NO;
    }];
}

- (void)enablePlayerAgain
{
    isPlayerEnabled = YES;
    __weak PlayerView *playerView = [MusicPlaybackController obtainRawPlayerView];
    [UIView animateWithDuration:1.0 animations:^{
        if(playerView){
            playerView.alpha = 1.0;
            playerView.userInteractionEnabled = YES;
        }
    }];
}

+ (BOOL)isPlayerEnabled
{
    return isPlayerEnabled;
}

+ (float)alphaValueForDisabledPlayer
{
    return disabledPlayerAlpa;
}

+ (BOOL)isPlayerOnScreen
{
    return playerIsOnScreen;
}

+ (void)playerWasKilled:(BOOL)killed
{
    [[SongPlayerCoordinator sharedInstance] privateIsPlayerOnScreenSetter:!killed];
}

- (CGRect)currentPlayerViewFrame
{
    return currentPlayerFrame;
}

- (void)recordCurrentPlayerViewFrame:(CGRect)newFrame
{
    currentPlayerFrame = newFrame;
}

static BOOL wasInPlayStateBeforeGUIDisabled = NO;
+ (void)placePlayerInDisabledState:(BOOL)disabled
{
    playerIsInDisabledState = disabled;
    if(disabled){
        if([MusicPlaybackController obtainRawAVPlayer].rate > 0){
            wasInPlayStateBeforeGUIDisabled = YES;
            ;
        }
        else
            wasInPlayStateBeforeGUIDisabled = NO;
    } else{
        wasInPlayStateBeforeGUIDisabled = NO;
    }
}

+ (BOOL)isPlayerInDisabledState
{
    return playerIsInDisabledState;
}

+ (BOOL)wasPlayerInPlayStateBeforeGUIDisabled
{
    return wasInPlayStateBeforeGUIDisabled;
}

+ (int)heightOfMinimizedPlayer
{
    int width, height;
    int smallVideoWidth = [SongPlayerCoordinator calculateSmallVideoWidth];
    if(canIgnoreToolbar){
        width = smallVideoWidth;
        height = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:width];
    } else{
        width = smallVideoWidth - amountToShrinkSmallPlayerWhenRespectingToolbar;
        height = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:width];
    }
    return height;
}

//private method
+ (int)calculateSmallVideoWidth
{
    //I always calculate the width of the player based on the width of the screen
    //when in portrait mode.
    int width;
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)){
        width = [UIScreen mainScreen].bounds.size.height/2.8 - MZSmallPlayerVideoFramePadding;
    } else{
        width = [UIScreen mainScreen].bounds.size.width/2.8 - MZSmallPlayerVideoFramePadding;
    }
    
    //make small video width smaller than usual on older (small) devices
    if(width > 200)
        width = 200;
    return width;
}

- (void)setSmallVideoWidth
{
    SMALL_VIDEO_WIDTH = [SongPlayerCoordinator calculateSmallVideoWidth];
}

- (void)privateIsPlayerOnScreenSetter:(BOOL)onScreen
{
    playerIsOnScreen = onScreen;
    [[NSNotificationCenter defaultCenter] postNotificationName:MZPlayerToggledOnScreenStatus
                                                        object:nil];
}

//should ONLY be used when you know for sure that the device orientation corresponds to a valid inteface orienation.
+ (UIInterfaceOrientation)convertDeviceOrientationToInferfaceOrientation:(UIDeviceOrientation)orientation
{
    switch (orientation)
    {
        case UIDeviceOrientationLandscapeLeft:
            return UIInterfaceOrientationLandscapeLeft;
            
        case UIDeviceOrientationLandscapeRight:
            return UIInterfaceOrientationLandscapeRight;
            
        case UIDeviceOrientationPortrait:
            return UIInterfaceOrientationPortrait;
            
        case UIDeviceOrientationPortraitUpsideDown:
            return UIInterfaceOrientationPortraitUpsideDown;
            
        default:
        {
            //device orientation is unknown. as a fallback, return actual interface orientation
            //of the apps window.
            return [UIApplication sharedApplication].statusBarOrientation;
        }
    }
}

@end
