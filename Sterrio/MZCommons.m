//
//  MZCommons.m
//  Sterrio
//
//  Created by Mark Zgaljic on 1/27/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZCommons.h"
#import "AppEnvironmentConstants.h"

@implementation MZCommons

#pragma mark - Threads
void safeSynchronousDispatchToMainQueue(void (^block)(void))
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

#pragma mark - Regex Helpers
+ (void)replaceCharsMatchingRegex:(NSString *)pattern
                        withChars:(NSString *)replacementChars
                         onString:(NSMutableString **)regexMe
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    [regex replaceMatchesInString:*regexMe
                          options:0
                            range:NSMakeRange(0, [*regexMe length])
                     withTemplate:replacementChars];
}

+ (NSString *)replaceCharsMatchingRegex:(NSString *)pattern
                              withChars:(NSString *)replacementChars
                        usingString:(NSString *)regexMe
{
    NSMutableString *returnMe = [NSMutableString stringWithString:regexMe];
    [MZCommons replaceCharsMatchingRegex:pattern withChars:replacementChars onString:&returnMe];
    return returnMe;
}

+ (BOOL)deleteCharsMatchingRegex:(NSString *)pattern onString:(NSMutableString **)regexMe
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSUInteger numMatches = [regex replaceMatchesInString:*regexMe
                                                  options:0
                                                    range:NSMakeRange(0, [*regexMe length])
                                             withTemplate:@""];
    return (numMatches > 0) ? YES : NO;
}

+ (NSString *)deleteCharsMatchingRegex:(NSString *)pattern usingString:(NSString *)regexMe
{
    NSMutableString *returnMe = [NSMutableString stringWithString:regexMe];
    [MZCommons deleteCharsMatchingRegex:pattern onString:&returnMe];
    return returnMe;
}

#pragma mark - AdMob requests
+ (GADRequest *)getNewAdmobRequest
{
    GADRequest *request = [GADRequest request];
    if(! [AppEnvironmentConstants isAppStoreBuild]) {
        request.testDevices = @[kGADSimulatorID, [AppEnvironmentConstants testingAdMobDeviceId]];
    }
    return request;
}

#pragma mark - GUI Helpers
+ (UIViewController *)topViewController
{
    return [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

//from snikch on Github
+ (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil)
        return rootViewController;
    
    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}

static UIStoryboard *mainStoryBoard = nil;
+ (UIStoryboard *)mainStoryboard
{
    NSAssert([NSThread isMainThread], @"Accesing main UIStoryboard off the main thread!");
    if(mainStoryBoard == nil) {
        mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        NSAssert(mainStoryBoard != nil, @"Cannot find main storyboard file. Was file name changed?");
    }
    return mainStoryBoard;
}

@end
