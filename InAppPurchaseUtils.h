//
//  InAppPurchaseUtils.h
//  Sterrio
//
//  Created by Mark Zgaljic on 12/13/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>


@interface InAppPurchaseUtils : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

+ (instancetype)sharedInstance;
- (void)purchaseAdRemoval;
- (void)restoreAdRemoval;

@end
