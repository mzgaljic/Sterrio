//
//  AppRatingUtils.h
//  Sterrio
//
//  Created by Mark Zgaljic on 2/16/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

/**
 * Class should only be accessed from the main thread.
 */
@interface AppRatingUtils : NSObject

+ (instancetype)sharedInstance;

- (void)redirectToMyAppInAppStoreWithDelay:(NSTimeInterval)interval;
- (void)redirectToMyAppInAppStore;

+ (BOOL)shouldAskUserIfTheyLikeApp;

@end
