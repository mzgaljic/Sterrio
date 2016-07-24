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
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@interface InAppPurchaseUtils ()
@property (nonatomic, strong) SKProduct *product;  //caching product for logging purposes (Fabric.io)
@property (nonatomic, strong) SKProductsRequest *productsRequest;
@end
@implementation InAppPurchaseUtils

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
        _adRemovalPriceText = @"";
    }
    return self;
}

- (void)purchaseAdRemoval
{
    self.product = nil;
    NSLog(@"User tapped remove ads button");
    
    if([SKPaymentQueue canMakePayments]){
        NSLog(@"User can make payments");
        self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:kRemoveAdsProductIdentifier]];
        self.productsRequest.delegate = self;
        [self.productsRequest start];
    } else{
        //this is called the user cannot make payments, most likely due to parental controls
        [self showPurchaseFailedAlert];
        [self logFabricPurchaseWithProduct:nil
                         purchaseSucceeded:NO
                        freeProductRestore:NO
                                  errorMsg:@"if([SKPaymentQueue canMakePayments]) is false. User unable to buy."];
    }
}

- (void)restoreAdRemoval
{
    self.product = nil;
    [self showSpinner];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark - Delegates
- (void)requestDidFinish:(SKRequest *)request
{
    self.productsRequest.delegate = nil;
    self.productsRequest = nil;
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    SKProduct *validProduct = nil;
    NSUInteger count = [response.products count];
    if(count > 0) {
        validProduct = [response.products objectAtIndex:0];
        self.product = validProduct;
        NSLog(@"Product Available!");
        //begin purchase...
        [[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProduct:validProduct]];
    }
    else if(!validProduct) {
        //this is called if your product id is not valid, this shouldn't be called unless that happens.
        [self showItemUnavailableOnStoreAlert];
        [self logFabricPurchaseWithProduct:nil
                         purchaseSucceeded:NO
                        freeProductRestore:NO
                                  errorMsg:@"No valid products returned. Product id is invalid?"];
        self.product = nil;
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSUInteger numTransactionsToRestore = queue.transactions.count;
    NSLog(@"received restored transactions: %lu", (unsigned long)numTransactionsToRestore);
    if(numTransactionsToRestore == 0) {
        [self hideSpinner];
        [self showNothingToRestoreAlert];
        [self logFabricPurchaseWithProduct:nil
                         purchaseSucceeded:NO
                        freeProductRestore:YES
                                  errorMsg:@"No restored products for this user."];
        self.product = nil;
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

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    
    [self hideSpinner];
    if(error.code != SKErrorPaymentCancelled) {
        [self showRestoreFailedAlert];
        NSLog(@"Transaction state -> Restore failed.");
        return;
    }
    NSLog(@"Transaction state -> Restore cancelled.");
}

static MRProgressOverlayView *hud;
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for(SKPaymentTransaction *transaction in transactions){
        switch(transaction.transactionState){
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"Transaction state -> Purchasing");
                //user is in the process of purchasing.
                [self showSpinner];
                break;
                
            case SKPaymentTransactionStatePurchased:  //(Cha-Ching!)
                NSLog(@"Transaction state -> Purchased");
                [self hideSpinner];
                [self removeAdsForUser];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [self logFabricPurchaseWithProduct:self.product
                                 purchaseSucceeded:YES
                                freeProductRestore:NO
                                          errorMsg:nil];
                break;
                
            case SKPaymentTransactionStateRestored:
                //user paid for this item before, will get it again for free.
                NSLog(@"Transaction state -> Restored");
                
                [self hideSpinner];
                [self removeAdsForUser];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [self logFabricPurchaseWithProduct:self.product
                                 purchaseSucceeded:YES
                                freeProductRestore:YES
                                          errorMsg:nil];
                break;
                
            case SKPaymentTransactionStateFailed:
            {
                //called when the transaction does not finish/fails
                NSString *errorMsg = nil;
                if(transaction.error.code == SKErrorPaymentCancelled){
                    errorMsg = @"Transaction state -> Cancelled";
                } else {
                    errorMsg = @"Transaction state -> Other purchase failure.";
                }
                NSLog(@"%@", errorMsg);
                [self hideSpinner];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [self logFabricPurchaseWithProduct:self.product
                                 purchaseSucceeded:YES
                                freeProductRestore:YES
                                          errorMsg:errorMsg];
            }
                break;
                
            case SKPaymentTransactionStateDeferred:
                //Don't block the UI, purchase is pending approval (by parent, etc.).
                [self hideSpinner];
                break;
        }
    }
    self.product = nil;
}

#pragma mark - Removing ads
//external, meant to be used throughout app.
- (void)removeAdsForUserBecauseOfFreeCampaign
{
    [self removeAdsForUser];
}

//don't expose this method.
- (void)removeAdsForUser
{
    [AppEnvironmentConstants adsHaveBeenRemoved:YES];
    //must be set now so the playerview frames are correct during animations.
    [AppEnvironmentConstants setBannerAdHeight:0];
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
    [self showAlertWithTitle:@"Success" message:msg btnText:@"OK"];
}

- (void)showRestoreFailedAlert
{
    NSString *msg = @"Restoring purchase failed.";
    [self showAlertWithTitle:@"Error" message:msg btnText:@"OK"];
}

- (void)showNothingToRestoreAlert
{
    NSLog(@"There are no purchases to restore.");
    NSString *title = @"Restore failed";
    NSString *msg = @"There are no purchases to restore.";
    [self showAlertWithTitle:title message:msg btnText:@"OK"];
}

- (void)showItemUnavailableOnStoreAlert
{
    NSLog(@"This item is currently unavailable on the App Store.");
    NSString *title = @"Item unavailable";
    NSString *message = @"This item is currently unavailable on the App Store.";
    [self showAlertWithTitle:title message:message btnText:@"OK"];
}

- (void)showPurchaseFailedAlert
{
    NSLog(@"Purchase failed: This is likely due to parental control settings on this device.");
    NSString *title = @"Purchase failed";
    NSString *message = @"This is likely due to parental control settings on this device.";
    [self showAlertWithTitle:title message:message btnText:@"OK"];
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

- (void)logFabricPurchaseWithProduct:(SKProduct *)product
                   purchaseSucceeded:(BOOL)success
                  freeProductRestore:(BOOL)freeRestore
                            errorMsg:(NSString *)errorMsg
{
    id purchaseError = (errorMsg == nil) ? @"" : errorMsg;
    NSString *currencyCode = nil;
    if(product) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [formatter setLocale:product.priceLocale];
        currencyCode = [formatter currencyCode];
    }
    
    [Answers logPurchaseWithPrice: (product == nil) ? nil : product.price
                         currency:currencyCode
                          success:[NSNumber numberWithBool:success]
                         itemName:(product == nil) ? nil : product.localizedTitle
                         itemType:@"In-App Purchase"
                           itemId:nil
                 customAttributes:@{@"Free product restore" : (freeRestore) ? @"Yes" : @"NO",
                                    @"Error W/ Purchase"    : purchaseError}];
    self.product = nil;
}

@end
