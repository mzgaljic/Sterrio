//
//  MZCommons.h
//  Sterrio
//
//  Created by Mark Zgaljic on 1/27/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
@import GoogleMobileAds;

@interface MZCommons : NSObject

#pragma mark - Threads
void safeSynchronousDispatchToMainQueue(void (^block)(void));

#pragma mark - Regex Helpers
+ (void)replaceCharsMatchingRegex:(NSString *)pattern
                        withChars:(NSString *)replacementChars
                         onString:(NSMutableString **)regexMe;
+ (NSString *)replaceCharsMatchingRegex:(NSString *)pattern
                              withChars:(NSString *)replacementChars
                               usingString:(NSString *)regexMe;

+ (BOOL)deleteCharsMatchingRegex:(NSString *)pattern onString:(NSMutableString **)regexMe;
+ (NSString *)deleteCharsMatchingRegex:(NSString *)pattern usingString:(NSString *)regexMe;

#pragma mark - AdMob requests
+ (GADRequest *)getNewAdmobRequest;

#pragma mark - GUI Helpers
+ (UIViewController *)topViewController;

@end
