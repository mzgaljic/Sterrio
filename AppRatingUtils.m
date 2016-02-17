//
//  AppRatingUtils.m
//  Sterrio
//
//  Created by Mark Zgaljic on 2/16/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "AppRatingUtils.h"

@implementation AppRatingUtils

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
    
}

@end
