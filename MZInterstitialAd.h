//
//  MZInterstitialAd.h
//  Sterrio
//
//  Created by Mark Zgaljic on 4/9/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
@import GoogleMobileAds;

@interface MZInterstitialAd : NSObject

+ (instancetype)sharedInstance;
- (GADInterstitial *)createAndLoadNewInterstitial;
- (GADInterstitial *)currentInterstitial;

@end
