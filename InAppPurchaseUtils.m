//
//  InAppPurchaseUtils.m
//  Sterrio
//
//  Created by Mark Zgaljic on 12/13/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import "InAppPurchaseUtils.h"
#import "SDCAlertController.h"
#import "AppEnvironmentConstants.h"
#import "MRProgress.h"

@implementation InAppPurchaseUtils

#define kRemoveAdsProductIdentifier @"com.mzgaljic.removeads"

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    if(self = [super init]){
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)purchaseAdRemoval
{
    NSLog(@"User tapped remove ads button");
    
    if([SKPaymentQueue canMakePayments]){
        NSLog(@"User can make payments");
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:kRemoveAdsProductIdentifier]];
        productsRequest.delegate = self;
        [productsRequest start];
    } else{
        //this is called the user cannot make payments, most likely due to parental controls
        NSLog(@"Purchase failed: This is likely due to parental control settings on this device.");
        [self showPurchaseFailedAlert];
    }
}

- (void)restoreAdRemoval
{
    [self showSpinner];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark - Delegates
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    SKProduct *validProduct = nil;
    NSUInteger count = [response.products count];
    if(count > 0) {
        validProduct = [response.products objectAtIndex:0];
        NSLog(@"Product Available!");
        //begin purchase...
        [[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProduct:validProduct]];
    }
    else if(!validProduct) {
        //this is called if your product id is not valid, this shouldn't be called unless that happens.
        NSLog(@"This item is currently unavailable on the App Store.");
        [self showItemUnavailableOnStoreAlert];
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSUInteger numTransactionsToRestore = queue.transactions.count;
    NSLog(@"received restored transactions: %lu", numTransactionsToRestore);
    if(numTransactionsToRestore == 0) {
        NSLog(@"There are no purchases to restore.");
        [self hideSpinner];
        [self showNothingToRestoreAlert];
        return;
    }
    
    for(SKPaymentTransaction *transaction in queue.transactions){
        if(transaction.transactionState == SKPaymentTransactionStateRestored){
            //called when the user successfully restores a purchase
            NSLog(@"Transaction state -> Restored");
            
            [self hideSpinner];
            [self removeAdsForUser];
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            
            //"Thank you" message isn't shown by ios automatically during a restore. Only for purchase.
            [self showRestoreSuccessAlert];
            break;
        }
    }
}

static MRProgressOverlayView *hud;
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for(SKPaymentTransaction *transaction in transactions){
        switch(transaction.transactionState){
            case SKPaymentTransactionStatePurchasing:
            {
                NSLog(@"Transaction state -> Purchasing");
                //user is in the process of purchasing.
                [self showSpinner];
                break;
            }
                
            case SKPaymentTransactionStatePurchased:  //(Cha-Ching!)
                NSLog(@"Transaction state -> Purchased");
                
                [self hideSpinner];
                [self removeAdsForUser];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                NSLog(@"Transaction state -> Restored");
                
                [self hideSpinner];
                [self removeAdsForUser];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                //called when the transaction does not finish/fails
                if(transaction.error.code == SKErrorPaymentCancelled){
                    NSLog(@"Transaction state -> Cancelled");
                  
                } else {
                    NSLog(@"Transaction state -> Other purchase failure.");
                }
                [self hideSpinner];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateDeferred:
                //Don't block the UI, purchase is pending approval (by parent, etc.).
                [self hideSpinner];
                break;
        }
    }
}

#pragma mark - Removing ads
- (void)removeAdsForUser
{
    [AppEnvironmentConstants adsHaveBeenRemoved:YES];
}

#pragma mark - Gui Utils
- (void)showSpinner
{
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    dispatch_async(dispatch_get_main_queue(), ^{
        hud = [MRProgressOverlayView showOverlayAddedTo:keyWindow
                                                  title:@""
                                                   mode:MRProgressOverlayViewModeIndeterminateSmall
                                               animated:YES];
    });
}

- (void)hideSpinner
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [hud dismiss:YES];
        hud = nil;
    });
}

- (void)showRestoreSuccessAlert
{
    NSString *msg = @"Your purchase has been restored.";
    [self showAlertWithTitle:@"Success" message:msg btnText:@"Okay"];
}

- (void)showNothingToRestoreAlert
{
    NSString *title = @"Restore failed";
    NSString *msg = @"There are no purchases to restore.";
    [self showAlertWithTitle:title message:msg btnText:@"Okay"];
}

- (void)showItemUnavailableOnStoreAlert
{
    
    NSString *title = @"Item unavailable";
    NSString *message = @"This item is currently unavailable on the App Store.";
    [self showAlertWithTitle:title message:message btnText:@"Okay"];
}

- (void)showPurchaseFailedAlert
{
    NSString *title = @"Purchase failed";
    NSString *message = @"This is likely due to parental control settings on this device.";
    [self showAlertWithTitle:title message:message btnText:@"Okay"];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)msg btnText:(NSString *)btnText
{
    SDCAlertController *alert =[SDCAlertController alertControllerWithTitle:title
                                                                    message:msg
                                                             preferredStyle:SDCAlertControllerStyleAlert];
    SDCAlertAction *okay = [SDCAlertAction actionWithTitle:btnText
                                                     style:SDCAlertActionStyleDefault
                                                   handler:^(SDCAlertAction *action) {}];
    [alert addAction:okay];
    [alert presentWithCompletion:nil];
}

@end
