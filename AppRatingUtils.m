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
#import "CoreDataManager.h"

@implementation AppRatingUtils

static long const ITUNES_APP_ID = 993519283;
NSString *templateReviewURL = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=APP_ID";

+ (instancetype)sharedInstance
{
    NSAssert([NSThread isMainThread], @"AppRatingUtils must only be accessed from the main thread.");
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

- (void)redirectToMyAppInAppStoreWithDelay:(NSTimeInterval)interval
{
    [self performSelector:@selector(redirectToMyAppInAppStore) withObject:nil afterDelay:interval];
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

static int numTimesMethodCalled = 0;
+ (BOOL)shouldAskUserIfTheyLikeApp
{
#ifdef DEBUG
    numTimesMethodCalled++;
    return (numTimesMethodCalled % 2 == 0);
#else
    // Something to log your sensitive data here
    const int minTimesAppMustBeLaunched = 20;
    const int minSongsInLibCount = 15;
    if([AppEnvironmentConstants hasUserRatedApp]) {
        return NO;
    }
    
    numTimesMethodCalled++;
    if(numTimesMethodCalled % 5 != 0) {
        //has it been 5 times since this method was called? If not, don't ask the user if they like
        //the app. This is a nice way of 'rate limiting' how frequently they will see the question
        //per app session.
        return NO;
    }
    
    if([AppEnvironmentConstants numberTimesUserLaunchedApp].longValue >= minTimesAppMustBeLaunched) {
        NSManagedObjectContext *moc = [CoreDataManager context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:[NSEntityDescription entityForName:@"Song" inManagedObjectContext:moc]];
        [request setIncludesSubentities:NO]; //Omit subentities.
        NSUInteger count = [moc countForFetchRequest:request error:nil];
        if(count != NSNotFound && count >= minSongsInLibCount) {
            return YES;
        }
    }
    return NO;
#endif
}

@end
