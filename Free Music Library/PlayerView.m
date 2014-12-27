//
//  PlayerView.m
//  Muzic
//
//  Created by Mark Zgaljic on 11/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlayerView.h"

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
        
        UISwipeGestureRecognizer *upSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                                action:@selector(userSwipedUp)];
        upSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
        [self addGestureRecognizer:upSwipeRecognizer];
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


#pragma mark - Other useful miscellaneous stuff

//detects when view (this AVPlayer) was tapped (fires when touch is released)
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [[[event allTouches] anyObject] locationInView:self];
    CGRect frame = self.frame;
    int x = touchLocation.x;
    int y = touchLocation.y;
    BOOL touchWithinVideoBounds = (x > 0 && y > 0 && x <= frame.size.width && y <= frame.size.height);
    if(touchWithinVideoBounds){
        [self segueToPlayerViewControllerIfAppropriate];
    }
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

- (void)segueToPlayerViewControllerIfAppropriate
{
    if(! [[SongPlayerCoordinator sharedInstance] isVideoPlayerExpanded])
        [SongPlayerViewDisplayUtility segueToSongPlayerViewControllerFrom:[self topViewController]];
}


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