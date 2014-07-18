//
//  AppEnvironmentConstants.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppEnvironmentConstants : NSObject

+ (BOOL)isAppInProductionMode;

//app settings
+ (short)preferredSizeSetting;
+ (void)setPreferredSizeSetting:(short)numUpToFive;

@end
