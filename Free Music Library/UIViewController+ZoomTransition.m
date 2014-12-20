//
//  UIViewController+ZoomTransition.m
//  Muzic
//
//  Created by Mark Zgaljic on 12/20/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "UIViewController+ZoomTransition.h"


@interface ContainerViewController : UIViewController { }
@end

@implementation ContainerViewController
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return(YES);
}
@end

@implementation UIViewController (ZoomTransition)

// get the screen size, compensating for orientation
- (CGSize)screenSize {
    // get the size of the screen (swapping dimensions for other orientations)
    CGSize size = [UIScreen mainScreen].bounds.size;
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        CGFloat width = size.width;
        size.width = size.height;
        size.height = width;
    }
    return(size);
}

// capture a screen-sized image of the receiver
- (UIImageView *)imageViewFromScreen {
    
    // get the root layer
    CALayer *layer = self.view.layer;
    while(layer.superlayer) {
        layer = layer.superlayer;
    }
    // get the size of the bitmap
    CGSize size = [self screenSize];
    // make a bitmap to copy the screen into
    UIGraphicsBeginImageContextWithOptions(
                                           size, YES,
                                           [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    // compensate for orientation
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        CGContextTranslateCTM(context, size.width, 0);
        CGContextRotateCTM(context, M_PI_2);
    }
    else if (orientation == UIInterfaceOrientationLandscapeRight) {
        CGContextTranslateCTM(context, 0, size.height);
        CGContextRotateCTM(context, - M_PI_2);
    }
    else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        CGContextTranslateCTM(context, size.width, size.height);
        CGContextRotateCTM(context, M_PI);
    }
    // render the layer into the bitmap
    [layer renderInContext:context];
    // get the image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    // close the context
    UIGraphicsEndImageContext();
    // make a view for the image
    UIImageView *imageView =
    [[UIImageView alloc] initWithImage:image];
    // done
    return(imageView);
}

// make a transform that causes the given subview to fill the screen
//  (when applied to an image of the screen)
- (CATransform3D)transformToFillScreenWithSubview:(UIView *)sourceView
                                 includeStatusBar:(BOOL)includeStatusBar {
    // get the root view
    UIView *rootView = sourceView;
    while (rootView.superview) rootView = rootView.superview;
    // by default, zoom from the view's bounds
    CGRect sourceRect = sourceView.bounds;
    // convert the source view's center and size into the coordinate
    //  system of the root view
    sourceRect = [sourceView convertRect:sourceRect toView:rootView];
    CGPoint sourceCenter = CGPointMake(
                                       CGRectGetMidX(sourceRect), CGRectGetMidY(sourceRect));
    CGSize sourceSize = sourceRect.size;
    // get the size and position we're expanding it to
    CGSize targetSize = [self screenSize];
    CGPoint targetCenter = CGPointMake(
                                       targetSize.width / 2.0,
                                       targetSize.height / 2.0);
    
    // scale so that the view fills the screen
    CATransform3D t = CATransform3DIdentity;
    CGFloat sourceAspect = sourceSize.width / sourceSize.height;
    CGFloat targetAspect = targetSize.width / targetSize.height;
    CGFloat scale = 1.0;
    if (sourceAspect > targetAspect)
        scale = targetSize.width / sourceSize.width;
    else
        scale = targetSize.height / sourceSize.height;
    t = CATransform3DScale(t, scale, scale, 1.0);
    // compensate for the status bar in the screen image
    CGFloat statusBarAdjustment = includeStatusBar ?
    (([UIApplication sharedApplication].statusBarFrame.size.height / 2.0)
     / scale) : 0.0;
    // transform to center the view
    t = CATransform3DTranslate(t,
                               (targetCenter.x - sourceCenter.x),
                               (targetCenter.y - sourceCenter.y) + statusBarAdjustment,
                               0.0);
    
    return(t);
}

- (void)expandView:(UIView *)sourceView toModalViewController:(UIViewController *)modalViewController {
    
    // get an image of the screen
    UIImageView *imageView = [self imageViewFromScreen];
    // show the modal view
    [self presentViewController:modalViewController animated:NO completion:nil];
    // make a window to display the transition on top of everything else
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.hidden = NO;
    window.backgroundColor = [UIColor blackColor];
    // make a view controller to display the image in
    ContainerViewController *vc = [[ContainerViewController alloc] init];
    vc.wantsFullScreenLayout = YES;
    // show the window
    [window setRootViewController:vc];
    [window makeKeyAndVisible];
    // add the image to the window
    [vc.view addSubview:imageView];
    
    // make a transform that makes the source view fill the screen
    CATransform3D t = [self transformToFillScreenWithSubview:sourceView includeStatusBar:(! modalViewController.wantsFullScreenLayout)];
    
    __weak UIWindow *weakWindow = window;
    __weak UIImageView *weakImageView = imageView;
    // animate the transform
    [UIView animateWithDuration:0.4
                     animations:^(void) {
                         weakImageView.layer.transform = t;
                     } completion:^(BOOL finished) {
                         // we're going to crossfade, so change the background to clear
                         weakImageView.backgroundColor = [UIColor clearColor];
                         // do a little crossfade
                         [UIView animateWithDuration:0.25
                                          animations:^(void) {
                                              weakImageView.alpha = 0.0;
                                          }
                                          completion:^(BOOL finished) {
                                              weakWindow.hidden = YES;
                                          }];
                     }];
}

- (void)dismissModalViewControllerToView:(UIView *)view {
    
    // temporarily remove the modal dialog so we can get an accurate screenshot with orientation applied
    UIViewController *modalViewController = self.presentedViewController;
    [self dismissViewControllerAnimated:NO completion:nil];
    
    // capture the screen
    UIImageView *imageView = [self imageViewFromScreen];
    // put the modal view controller back
    [self presentViewController:modalViewController animated:NO completion:nil];
    
    // make a window to display the transition on top of everything else
    UIWindow *window =
    [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.hidden = NO;
    window.backgroundColor = [UIColor clearColor];
    // make a view controller to display the image in
    ContainerViewController *vc = [[ContainerViewController alloc] init];
    vc.wantsFullScreenLayout = YES;
    // show the window
    [window setRootViewController:vc];
    [window makeKeyAndVisible];
    // add the image to the window
    [vc.view addSubview:imageView];
    
    // make the subview initially fill the screen
    imageView.layer.transform = [self transformToFillScreenWithSubview:view includeStatusBar:(! self.modalViewController.wantsFullScreenLayout)];
    
    // animate a little crossfade
    imageView.alpha = 0.0;
    __weak UIWindow *weakWindow = window;
    __weak UIImageView *weakImageView = imageView;
    [UIView animateWithDuration:0.15
                     animations:^(void) {
                         weakImageView.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         // remove the modal view
                         [self dismissViewControllerAnimated:NO completion:nil];
                         // set the background so the real screen won't show through
                         weakWindow.backgroundColor = [UIColor blackColor];
                         // animate the screen shrinking back to normal
                         [UIView animateWithDuration:0.4 
                                          animations:^(void) {
                                              weakImageView.layer.transform = CATransform3DIdentity;
                                          }
                                          completion:^(BOOL finished) {
                                              // hide the transition stuff
                                              weakWindow.hidden = YES;
                                          }];
                     }];
    
}

@end
