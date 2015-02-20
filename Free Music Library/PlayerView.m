//
//  PlayerView.m
//  Muzic
//
//  Created by Mark Zgaljic on 11/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlayerView.h"
#import "SongPlayerViewController.h"


@interface PlayerView ()
{
    CGPoint gestureStartPoint;
    BOOL userDidSwipeUp;
    BOOL userDidSwipeDown;
    BOOL userDidTap;
    UIInterfaceOrientation lastOrientation;
    int killSlideXBoundary;
    NSMutableArray *lastTouchesDirection;
}
@end
@implementation PlayerView

static UIImageView *screenshotOfPlayer;
typedef enum {leftDirection, rightDirection} HorizontalDirection;

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
}

#pragma mark - UIView lifecycle
- (id)init
{
    if (self = [super init]) {
        AVPlayerLayer *layer = (AVPlayerLayer *)self.layer;
        layer.masksToBounds = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationNeedsToChanged)
                                                     name:UIDeviceOrientationDidChangeNotification object:nil];
        
        lastOrientation = [UIApplication sharedApplication].statusBarOrientation;
        self.multipleTouchEnabled = NO;
        lastTouchesDirection = [NSMutableArray array];
        
        UITapGestureRecognizer *tap;
        UISwipeGestureRecognizer *up;
        UISwipeGestureRecognizer *down;
        tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(userTappedPlayer)];
        up = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                       action:@selector(userSwipedUp)];
        down = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                         action:@selector(userSwipedDown)];
        up.direction = UISwipeGestureRecognizerDirectionUp;
        down.direction = UISwipeGestureRecognizerDirectionDown;
        [self addGestureRecognizer:tap];
        [self addGestureRecognizer:up];
        [self addGestureRecognizer:down];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - AVPlayer & AVPlayerLayer code
+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (void)removeLayerFromPlayer
{    
    AVPlayerLayer *playerLayer = (AVPlayerLayer *)[self layer];
    [playerLayer setPlayer:nil];
}

- (UIImage *)screenshotOfPlayer
{
    return [self viewAsScreenshot];
}

- (void)reattachLayerToPlayer
{
    if(screenshotOfPlayer){
        [screenshotOfPlayer removeFromSuperview];
        screenshotOfPlayer = nil;
    }
    AVPlayerLayer *playerLayer = (AVPlayerLayer *)[self layer];
    [playerLayer setPlayer:[MusicPlaybackController obtainRawAVPlayer]];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

#pragma mark - Responding to getures
- (void)userSwipedUp
{
    userDidSwipeUp = YES;
    [self segueToPlayerViewControllerIfAppropriate];
}

- (void)userSwipedDown
{
    userDidSwipeDown = YES;
    [self popPlayerViewControllerIfAppropriate];
}

- (void)userTappedPlayer
{
    userDidTap = YES;
    [self segueToPlayerViewControllerIfAppropriate];
}

- (void)userKilledPlayer
{
    AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    [player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:nil]];
    [SongPlayerCoordinator playerWasKilled:YES];
}

#pragma mark - Orientation and view "touch" code
//used to help the touchesMoved method below get the swipe length
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    userDidSwipeUp = NO;
    userDidSwipeDown = NO;
    userDidTap = NO;
    
    UITouch *touch = [touches anyObject];
    gestureStartPoint = [touch locationInView:self];
    
    int screenWidth = [UIScreen mainScreen].bounds.size.width;
    killSlideXBoundary = screenWidth * 0.85;
    killSlideXBoundary = screenWidth - killSlideXBoundary;
    [lastTouchesDirection removeAllObjects];
}

//used to get a "length" for each swipe gesture
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(userDidSwipeUp || userDidSwipeDown || userDidTap ||
       [SongPlayerCoordinator isVideoPlayerExpanded])
        return;
    
    UITouch *touch = [touches anyObject];
    CGPoint currentPosition = [touch locationInView:self];
    CGFloat deltaXX = (gestureStartPoint.x - currentPosition.x);  //positive = left
    
    if(lastTouchesDirection.count > 5)
        [lastTouchesDirection removeObjectAtIndex:0];
    if(deltaXX > 0)
        [lastTouchesDirection addObject:[NSNumber numberWithInt:leftDirection]];
    else
        [lastTouchesDirection addObject:[NSNumber numberWithInt:rightDirection]];
    
    //make view follow finger
    CGRect frame = self.frame;
    self.frame = CGRectMake(frame.origin.x - deltaXX,
                            frame.origin.y,
                            frame.size.width,
                            frame.size.height);
}

//detects when view (this AVPlayer) was tapped (fires when touch is released)
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    BOOL playerExpanded = [SongPlayerCoordinator isVideoPlayerExpanded];
    if(userDidSwipeDown || userDidSwipeUp || userDidTap || playerExpanded){
        [lastTouchesDirection removeAllObjects];
        return;
    }
    
    if(! playerExpanded && !userDidSwipeUp && !userDidSwipeDown && !userDidTap){
        BOOL endMotionSwipeLeft = NO;
        int count = 0;
        for(int i = 0; i < lastTouchesDirection.count; i++){
            if(i > 2)
                break;
            if([lastTouchesDirection[i] intValue] == leftDirection)
                count++;
        }
        if(count >= 2)
            endMotionSwipeLeft = YES;
        
        int screenWidth = [UIScreen mainScreen].bounds.size.width;
        
        //this will be the real "kill" boundary if the user let go
        //before reaching the real boundary and was heading in the direction
        //of the kill boundary.
        int motionBoundaryKill = screenWidth/2.5;
        if(lastOrientation == UIInterfaceOrientationPortrait ||
           lastOrientation == UIInterfaceOrientationPortraitUpsideDown)
            motionBoundaryKill = killSlideXBoundary;
        
        //user has moved player past "kill" boundary
        if((self.frame.origin.x <= killSlideXBoundary && endMotionSwipeLeft) ||
           (endMotionSwipeLeft && self.frame.origin.x <= motionBoundaryKill)){
            //user wants to kill player
            [self movePlayerOffScreenAndKillPlayback];
        }else{
            //user changed his/her mind
            [self movePlayerBackToOriginalLocation];
        }
    }
    [lastTouchesDirection removeAllObjects];
    userDidSwipeUp = NO;
    userDidSwipeDown = NO;
    userDidTap = NO;
}

//called during low memory events by system, etc
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    BOOL moveViewBack = YES;
    if(userDidSwipeDown || userDidSwipeUp || userDidTap)
        moveViewBack = NO;
    
    userDidSwipeUp = NO;
    userDidSwipeDown = NO;
    userDidTap = NO;
    
    //check if user tapped or swiped. if not, then just animate it back to its original
    //position...dont want to do something the user didnt want.
    if(moveViewBack)
        [self movePlayerBackToOriginalLocation];
    [lastTouchesDirection removeAllObjects];
}

- (void)movePlayerBackToOriginalLocation
{
    __weak PlayerView *weakSelf = self;
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         if(lastOrientation == UIInterfaceOrientationPortrait ||
                            lastOrientation == UIInterfaceOrientationPortraitUpsideDown){
                             weakSelf.frame = [[SongPlayerCoordinator sharedInstance] smallPlayerFrameInPortrait];
                         } else{
                             weakSelf.frame = [[SongPlayerCoordinator sharedInstance] smallPlayerFrameInLandscape];
                         }
                     } completion:nil];
}

- (void)movePlayerOffScreenAndKillPlayback
{
    __weak PlayerView *weakSelf = self;
    int screenWidth = [UIScreen mainScreen].bounds.size.width;
    int width = weakSelf.frame.size.width;
    [UIView animateWithDuration:0.65
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         weakSelf.alpha = 0;
                         weakSelf.frame = CGRectMake(0 - width,
                                                     weakSelf.frame.origin.y,
                                                     weakSelf.frame.size.width,
                                                     weakSelf.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         [weakSelf userKilledPlayer];
                         
                         //move frame back to bottom right so it looks the same
                         //the next time the player is opened
                         weakSelf.frame = CGRectMake(screenWidth - width,
                                                     weakSelf.frame.origin.y + weakSelf.frame.size.height ,
                                                     weakSelf.frame.size.width,
                                                     weakSelf.frame.size.height);
                     }];
}

#pragma mark - Rotation
//will rotate the video ONLY when it is small.
//The SongPlayerViewController class handles the big video rotation.
- (void)orientationNeedsToChanged
{
    if([SongPlayerCoordinator isVideoPlayerExpanded])
        return;   //don't touch the player when it is expanded
    else{
        UIInterfaceOrientation newOrientation = [UIApplication sharedApplication].statusBarOrientation;
        lastOrientation = newOrientation;
        [[SongPlayerCoordinator sharedInstance] shrunkenVideoPlayerNeedsToBeRotated];
    }
}

#pragma mark - Handling Poping and pushing of the player VC along with this view
- (void)segueToPlayerViewControllerIfAppropriate
{
    [SongPlayerViewDisplayUtility segueToSongPlayerViewControllerFrom:[self topViewController]];
}

- (void)popPlayerViewControllerIfAppropriate
{
    if([SongPlayerCoordinator isVideoPlayerExpanded]){
        //same code as in MyAlerts...this code is better than
        UIWindow *keyWindow = [[[UIApplication sharedApplication] delegate] window];
        SongPlayerViewController *vc =  (SongPlayerViewController *)[keyWindow visibleViewController];
        [vc preDealloc];
        BOOL animated = NO;
        if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)
            animated = YES;
        
        [vc dismissViewControllerAnimated:animated completion:nil];
        [[SongPlayerCoordinator sharedInstance] beginShrinkingVideoPlayer];
    }
}



#pragma mark - Boring utility methods
- (UIViewController *)topViewController{
    return [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

//from snikch on Github
- (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil)
        return rootViewController;
    
    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}


@end