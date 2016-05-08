//
//  InAppPurchaseUtils.h
//  Sterrio
//
//  Created by Mark Zgaljic on 12/13/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#define kRemoveAdsProductIdentifier @"com.mzgaljic.sterrio.removeads"
@interface InAppPurchaseUtils : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, strong, readwrite) NSString *adRemovalPriceText;

+ (instancetype)sharedInstance;
- (void)purchaseAdRemoval;
- (void)restoreAdRemoval;

- (void)setAdRemovalPriceText:(NSString *)priceText;
- (NSString *)adRemovalPriceText;

@end
