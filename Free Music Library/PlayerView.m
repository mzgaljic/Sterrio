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
    BOOL didFailToExpandWithSwipe;
    BOOL userTouchedDown;
    UIInterfaceOrientation lastOrientation;
    int killSlideXBoundary;
    NSMutableArray *lastTouchesDirection;
}
@property (nonatomic, strong) NSTimer *timer;
@end
@implementation PlayerView
typedef enum {leftDirection, rightDirection} HorizontalDirection;

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

static UIImageView *screenshotOfPlayer;
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
    [self segueToPlayerViewControllerIfAppropriate];
}

- (void)userSwipedDown
{
    [self popPlayerViewControllerIfAppropriate];
}

- (void)userKilledPlayer
{
    AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
    [player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:nil]];
}

#pragma mark - Orientation and view "touch" code
//used to help the touchesMoved method below get the swipe length
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    userTouchedDown = YES;
    
    UITouch *touch = [touches anyObject];
    gestureStartPoint = [touch locationInView:self];
    didFailToExpandWithSwipe = NO;
    
    int screenWidth = [UIScreen mainScreen].bounds.size.width;
    killSlideXBoundary = screenWidth * 0.85;
    killSlideXBoundary = screenWidth - killSlideXBoundary;
    [lastTouchesDirection removeAllObjects];
}

//used to get a "length" for each swipe gesture
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.timer invalidate];
    self.timer = nil;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                  target:self
                                                selector:@selector(manualTouchesEnded:)
                                                userInfo:@[touches, event]
                                                 repeats:NO];
    
    UITouch *touch = [touches anyObject];
    CGPoint currentPosition = [touch locationInView:self];
    
    CGFloat deltaYY = (gestureStartPoint.y - currentPosition.y); // positive = up, negative = down
    CGFloat deltaXX = (gestureStartPoint.x - currentPosition.x);  //positive = left
    
    CGFloat deltaX = fabsf(gestureStartPoint.x - currentPosition.x); // will always be positive
    CGFloat deltaY = fabsf(gestureStartPoint.y - currentPosition.y); // will always be positive
    
    if(lastTouchesDirection.count > 5)
        [lastTouchesDirection removeObjectAtIndex:0];
    if(deltaXX > 0)
        [lastTouchesDirection addObject:[NSNumber numberWithInt:leftDirection]];
    else
        [lastTouchesDirection addObject:[NSNumber numberWithInt:rightDirection]];
    
    if (deltaY >= MZMinVideoPlayerSwipeLengthDown && deltaX <= MZMaxVideoPlayerSwipeVariance && deltaYY <= 0) {
        //Vertical down swipe detected
        [self userSwipedDown];
        didFailToExpandWithSwipe = NO;
        return;
    }
    else if (deltaY >= MZMinVideoPlayerSwipeLengthUp && deltaX <= MZMaxVideoPlayerSwipeVariance && deltaYY > 0) {
        //Vertical up swipe detected
        [self userSwipedUp];
        didFailToExpandWithSwipe = NO;
        return;
    }
    else if(deltaY <= MZMinVideoPlayerSwipeLengthUp){
        
        if([[SongPlayerCoordinator sharedInstance] isVideoPlayerExpanded])
            return;
        
        //make view follow finger
        CGRect frame = self.frame;
        self.frame = CGRectMake(frame.origin.x - deltaXX,
                                frame.origin.y,
                                frame.size.width,
                                frame.size.height);
        
        CGRect startFrame = [[SongPlayerCoordinator sharedInstance] smallPlayerFrameInPortrait];
        //detect if user is in progress of making a swipe up gesture (avoid setting didFailToExpandWithSwipe = YES)
        if(MZMaxVideoPlayerSwipeVariance >= abs((currentPosition.x - startFrame.origin.x)) && deltaYY > (MZMinVideoPlayerSwipeLengthUp / 10))
            return;
    }
    didFailToExpandWithSwipe = YES;
}

//detects when view (this AVPlayer) was tapped (fires when touch is released)
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.timer invalidate];
    self.timer = nil;
    
    BOOL playerExpanded = [[SongPlayerCoordinator sharedInstance] isVideoPlayerExpanded];
    //this if statement only executes IF the player is already expanded
    if(userTouchedDown && playerExpanded){
        [lastTouchesDirection removeAllObjects];
        return;
    }
    
    if(! playerExpanded){
        CGPoint touchLocation = [[[event allTouches] anyObject] locationInView:self];
        CGRect frame = self.frame;
        int x = touchLocation.x;
        int y = touchLocation.y;
        BOOL touchWithinVideoBounds = (x > 0 && y > 0 && x <= frame.size.width && y <= frame.size.height);
        //also check to avoid the situation where a swipe was too small but is still within
        //the view bounds. in this case we would NOT want to expand until a direct touch or
        //better swipe is performed.
        if(touchWithinVideoBounds && !didFailToExpandWithSwipe){
            //same code as in "segueToPlayerViewControllerIfAppropriate", just skipping extra calls...
            [SongPlayerViewDisplayUtility segueToSongPlayerViewControllerFrom:[self topViewController]];
            [lastTouchesDirection removeAllObjects];
            return;
        } else{
            if(! didFailToExpandWithSwipe)
                return;
            
            //code below here should only be executed if the user did not successfully expand the player via a swipe
            __weak PlayerView *weakSelf = self;
            int width = weakSelf.frame.size.width;
            int screenWidth = [UIScreen mainScreen].bounds.size.width;
            
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
            
            //return player to original frame since the user has decided not to kill the player
            else if(self.frame.origin.x > killSlideXBoundary || !endMotionSwipeLeft){
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
            [lastTouchesDirection removeAllObjects];
        }
    }
}


- (void)manualTouchesEnded:(NSTimer *)timer
{
    NSArray *data = [timer userInfo];
    [self touchesEnded:data[0] withEvent:data[1]];
}

//called during low memory events by system, etc
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}


//will rotate the video ONLY when it is small.
//The SongPlayerViewController class handles the big video rotation.
- (void)orientationNeedsToChanged
{
    if([[SongPlayerCoordinator sharedInstance] isVideoPlayerExpanded])
        return;   //don't touch the player when it is expanded
    else{
        UIInterfaceOrientation newOrientation = [UIApplication sharedApplication].statusBarOrientation;
        if(newOrientation == lastOrientation)
            return;
        else
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
    if([[SongPlayerCoordinator sharedInstance] isVideoPlayerExpanded]){
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