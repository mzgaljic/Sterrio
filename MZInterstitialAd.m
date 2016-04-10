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

- (GADInterstitial *)createAndLoadNewInterstitial
{
    if(self.interstitialAd == nil) {
        self.interstitialAd = [[GADInterstitial alloc] initWithAdUnitID:MZAdMobUnitId];
        self.interstitialAd.delegate = self;
    }
    [self.interstitialAd loadRequest:[MZCommons getNewAdmobRequest]];
    return self.interstitialAd;
}
- (GADInterstitial *)currentInterstitial
{
    return self.interstitialAd;
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial {
    self.interstitialAd = [self createAndLoadNewInterstitial];
}

- (void)interstitialDidReceiveAd:(GADInterstitial *)ad
{
    
}

@end
