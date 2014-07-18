//
//  AppEnvironmentConstants.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AppEnvironmentConstants.h"

@implementation AppEnvironmentConstants

static const BOOL PRODUCTION_MODE = NO;
static short preferredSizeValue;

+ (BOOL)isAppInProductionMode
{
    return PRODUCTION_MODE;
}

//app settings
+ (short)preferredSizeSetting
{
    return preferredSizeValue;
}

+ (void)setPreferredSizeSetting:(short)numUpToFive
{
    preferredSizeValue = numUpToFive;
}
@end
