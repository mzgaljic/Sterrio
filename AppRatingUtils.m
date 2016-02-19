//
//  AppRatingUtils.m
//  Sterrio
//
//  Created by Mark Zgaljic on 2/16/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "AppRatingUtils.h"

@interface AppRatingUtils ()
{
    NSString *appIdString;
}
@end
@implementation AppRatingUtils

static UIStatusBarStyle _statusBarStyle;
NSString *const kAppiraterRatedCurrentVersion = @"mzUserRatedCurrentVersion";
NSString *templateReviewURL = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=APP_ID";

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
        //[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)showAppRatingModalToUser
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:YES forKey:kAppiraterRatedCurrentVersion];
    [userDefaults synchronize];
    
    //Use the in-app StoreKit view if available and imported. This works in the simulator.
    if (NSStringFromClass([SKStoreProductViewController class]) != nil) {
        SKStoreProductViewController *storeViewController = [[SKStoreProductViewController alloc] init];
        NSNumber *appId = [NSNumber numberWithInteger:appIdString.integerValue];
        [storeViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier:appId} completionBlock:nil];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:storeViewController animated:YES completion:^{
            //Temporarily use a black status bar to match the StoreKit view.
            [AppRatingUtils setStatusBarStyle:[UIApplication sharedApplication].statusBarStyle];
            [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent
                                                       animated:YES];
        }];
        
        //Use the standard openUrl method if StoreKit is unavailable.
    } else {
        NSString *reviewURL = [templateReviewURL stringByReplacingOccurrencesOfString:@"APP_ID"
                                                                           withString:[NSString stringWithFormat:@"%@", appIdString]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
    }
}

#pragma mark - Helpers
+ (void)setStatusBarStyle:(UIStatusBarStyle)style {
    _statusBarStyle = style;
}
@end
