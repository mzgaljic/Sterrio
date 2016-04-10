//
//  MZInterstitialAd.h
//  Sterrio
//
//  Created by Mark Zgaljic on 4/9/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
@import GoogleMobileAds;

typedef void (^AdDismissed)();

@interface MZInterstitialAd : NSObject

+ (instancetype)sharedInstance;
- (void)loadNewInterstitialIfNecessary;

/*
 * Presents the Interstitial on a specific VC.
 */
- (void)presentIfReadyWithRootVc:(UIViewController *)vc withDismissAction:(AdDismissed)dismissBlock;

/*
 * Convenience method, presents the Interstitial on the top-most (visible) VC.
 */
- (void)presentIfReadyWithDismissAction:(AdDismissed)dismissBlock;

@end
