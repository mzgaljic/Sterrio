//
//  MZInterstitialAd.m
//  Sterrio
//
//  Created by Mark Zgaljic on 4/9/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZInterstitialAd.h"

@interface MZInterstitialAd () <GADInterstitialDelegate>
@property (nonatomic, strong) GADInterstitial *interstitialAd;
@property (copy) AdDismissed adDismissBlock;
@end
@implementation MZInterstitialAd

+ (instancetype)sharedInstance
{
    NSAssert([NSThread isMainThread], @"MZInterstitialAd must only be accessed from the main thread.");
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (void)loadNewInterstitialIfNecessary
{
    if(self.interstitialAd == nil) {
        self.interstitialAd = [[GADInterstitial alloc] initWithAdUnitID:MZAdMobUnitId];
        self.interstitialAd.delegate = self;
        [self.interstitialAd loadRequest:[MZCommons getNewAdmobRequest]];
    }
}

- (void)presentIfReadyWithRootVc:(UIViewController *)vc withDismissAction:(AdDismissed)dismissBlock
{
    if(self.interstitialAd != nil && self.interstitialAd.isReady) {
        [self.interstitialAd presentFromRootViewController:vc];
        self.adDismissBlock = dismissBlock;
    }
}

- (void)presentIfReadyWithDismissAction:(AdDismissed)dismissBlock
{
    [self presentIfReadyWithRootVc:[MZCommons topViewController] withDismissAction:dismissBlock];
}

#pragma mark - Delegate methods
- (void)interstitialDidDismissScreen:(GADInterstitial *)ad
{
    if(self.adDismissBlock) {
        self.adDismissBlock();
    }
    self.adDismissBlock = nil;
}

@end
