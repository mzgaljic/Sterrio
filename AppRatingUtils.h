//
//  AppRatingUtils.h
//  Sterrio
//
//  Created by Mark Zgaljic on 2/16/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface AppRatingUtils : NSObject

+ (instancetype)sharedInstance;
- (void)redirectToMyAppInAppStore;

@end
