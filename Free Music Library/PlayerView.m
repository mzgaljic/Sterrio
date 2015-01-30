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
}
@end
@implementation PlayerView

#pragma mark - UIView lifecycle
- (id)init
{
    if (self = [super init]) {
        AVPlayerLayer *layer = (AVPlayerLayer *)self.layer;
        layer.masksToBounds = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationNeedsToChanged)
                                                     name:UIDeviceOrientationDidChangeNotification object:nil];
        
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


#pragma mark - Orientation and view "touch" code
//detects when view (this AVPlayer) was tapped (fires when touch is released)
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    BOOL alreadySegued = NO;
    if(userTouchedDown)
        alreadySegued = [self segueToPlayerViewControllerIfAppropriate];
    if(! [[SongPlayerCoordinator sharedInstance] isVideoPlayerExpanded] && !alreadySegued){
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
        }
    }
}

//used to help the touchesMoved method below get the swipe length
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    userTouchedDown = YES;
    
    UITouch *touch = [touches anyObject];
    gestureStartPoint = [touch locationInView:self];
    didFailToExpandWithSwipe = NO;
}

//used to get a "length" for each swipe gesture
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint currentPosition = [touch locationInView:self];

    CGFloat deltaYY = (gestureStartPoint.y - currentPosition.y); // positive = up, negative = down
    
    CGFloat deltaX = fabsf(gestureStartPoint.x - currentPosition.x); // will always be positive
    CGFloat deltaY = fabsf(gestureStartPoint.y - currentPosition.y); // will always be positive
    
    if (deltaY >= MZMinVideoPlayerSwipeLengthDown && deltaX <= MZMaxVideoPlayerSwipeVariance) {
        if (deltaYY <= 0) {
            //Vertical down swipe detected
            [self userSwipedDown];
            didFailToExpandWithSwipe = NO;
            return;
        }
    }
    else if (deltaY >= MZMinVideoPlayerSwipeLengthUp && deltaX <= MZMaxVideoPlayerSwipeVariance) {
        if (deltaYY > 0) {
            //Vertical up swipe detected
            [self userSwipedUp];
            didFailToExpandWithSwipe = NO;
            return;
        }
    }
    didFailToExpandWithSwipe = YES;
}

//will rotate the video ONLY when it is small.
//The SongPlayerViewController class handles the big video rotation.
- (void)orientationNeedsToChanged
{
    if([[SongPlayerCoordinator sharedInstance] isVideoPlayerExpanded])
        return;   //don't touch the player when it is expanded
    else
        [[SongPlayerCoordinator sharedInstance] shrunkenVideoPlayerNeedsToBeRotated];
}

#pragma mark - Handling Poping and pushing of the player VC along with this view
- (BOOL)segueToPlayerViewControllerIfAppropriate
{
    BOOL willSegue = NO;
    if(! [[SongPlayerCoordinator sharedInstance] isVideoPlayerExpanded]){
        willSegue = YES;
        [SongPlayerViewDisplayUtility segueToSongPlayerViewControllerFrom:[self topViewController]];
    }
    return willSegue;
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