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

+ (BOOL)isAppInProductionMode
{
    return PRODUCTION_MODE;
}

@end
