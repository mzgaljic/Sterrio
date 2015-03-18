//
//  SDCAlertView+DuplicateAlertsPreventer.m
//  Muzic
//
//  Created by Mark Zgaljic on 12/31/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "SDCAlertView+DuplicateAlertsPreventer.h"
#include <mach/mach_time.h>

@implementation SDCAlertView (DuplicateAlertsPreventer)

static NSString *mostRecentTitle;
static NSString *mostRecentMsg;
static uint64_t lastTimeUsed;

- (id)initWithTitle:(NSString *)title
            message:(NSString *)msg
           delegate:(id)delegate
  cancelButtonTitle:(NSString *)cancelBtnTitle
    avoidDuplicates:(BOOL)avoid
{
    if(avoid){
        if([mostRecentTitle isEqual:title] && [mostRecentMsg isEqual:msg]){
            uint64_t elapsedTime = mach_absolute_time() - lastTimeUsed;
            double secondsElapsed = MachTimeToSecs(elapsedTime);
            lastTimeUsed = mach_absolute_time();
            if(secondsElapsed <= 1)
                return nil;
        }
    }
    mostRecentTitle = title;
    mostRecentMsg = msg;
    lastTimeUsed = mach_absolute_time();
    
    return [self initWithTitle:title
                       message:msg
                      delegate:delegate
             cancelButtonTitle:cancelBtnTitle
             otherButtonTitles:nil];
}

double MachTimeToSecs(uint64_t time)
{
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    return (double)time * (double)timebase.numer /
    (double)timebase.denom / 1e9;
}

@end
