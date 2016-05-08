//
//  InAppProductPriceHelper.m
//  Sterrio
//
//  Created by Mark Zgaljic on 5/7/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "InAppProductPriceHelper.h"
#import "AppEnvironmentConstants.h"
#import "InAppPurchaseUtils.h"

@interface InAppProductPriceHelper () <SKProductsRequestDelegate>
@property (nonatomic, strong) SKProductsRequest *productsRequest;  //for fetching cost of ad removal.
@end
@implementation InAppProductPriceHelper

static BOOL adProductPriceFetchAlreadyCalled = NO;
static InAppProductPriceHelper *selfRetained = nil;

- (void)beginFetchingAdRemovalPriceInfoAndSetWhenDone
{
    if(adProductPriceFetchAlreadyCalled || [AppEnvironmentConstants areAdsRemoved]) {
        return;
    }
    adProductPriceFetchAlreadyCalled = YES;
    NSSet *productIds = [NSSet setWithArray:@[kRemoveAdsProductIdentifier]];
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIds];
    self.productsRequest.delegate = self;
    
    // This will trigger the SKProductsRequestDelegate callbacks
    [self.productsRequest start];
    selfRetained = self;  //will release after products request succeeds or fails.
}

- (void)requestDidFinish:(SKRequest *)request
{
    self.productsRequest.delegate = nil;
    self.productsRequest = nil;
    //allow us to be dealloced (assuming no other classes explicitly wanted to retain us.)
    selfRetained = nil;
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray *products = response.products;
    NSString *adRemovalPriceText;
    if(products.count == 1) {
        SKProduct *adRemovalProduct = [products firstObject];
        if([adRemovalProduct.price compare:[NSNumber numberWithInt:0]] == NSOrderedSame) {
            //don't show price if it's 0.0, that just looks stupid on screen.
            //likely only occurrs in sandbox or if user already bought this item.
            adRemovalPriceText = @"";
        } else {
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
            [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
            [numberFormatter setLocale:adRemovalProduct.priceLocale];
            adRemovalPriceText = [numberFormatter stringFromNumber:adRemovalProduct.price];
        }
    } else {
        adRemovalPriceText = @"";
    }
    [InAppPurchaseUtils sharedInstance].adRemovalPriceText = adRemovalPriceText;
}

@end
