//
//  AppRatingUtils.m
//  Sterrio
//
//  Created by Mark Zgaljic on 2/16/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "AppRatingUtils.h"
#import "AppEnvironmentConstants.h"
#import <Fabric/Fabric.h>

@implementation AppRatingUtils

static long const ITUNES_APP_ID = 993519283;
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
    if(self = [super init]){}
    return self;
}

- (void)redirectToMyAppInAppStore
{
    //assume they'll actually rate this if they are going to the app store. No way of determining
    //if they actually rated it for real without nasty hacks.
    [AppEnvironmentConstants setUserHasRatedMyApp:YES];
    [Answers logCustomEventWithName:@"AppStore rating/review redirect" customAttributes:nil];
    
    NSString *urlString = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%ld", ITUNES_APP_ID];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

@end
