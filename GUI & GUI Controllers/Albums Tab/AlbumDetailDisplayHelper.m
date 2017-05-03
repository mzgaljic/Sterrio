
//
//  AlbumDetailDisplayHelper.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/27/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "AlbumDetailDisplayHelper.h"

@implementation AlbumDetailDisplayHelper

+ (NSString *)convertSecondsToPrintableNSStringWithSeconds:(NSUInteger)value
{
    NSString *secondsToStringReturn;
    
    NSUInteger totalSeconds = value;
    int seconds = (int)(totalSeconds % MZSecondsInAMinute);
    NSUInteger totalMinutes = totalSeconds / MZSecondsInAMinute;
    int minutes = (int)(totalMinutes % MZMinutesInAnHour);
    int hours = (int)(totalMinutes / MZMinutesInAnHour);
    
    if(minutes < 10 && hours == 0)  //we can shorten the text
        secondsToStringReturn = [NSString stringWithFormat:@"%i:%02d", minutes, seconds];
    
    else if(hours > 0)
    {
        if(hours <= 9)
            secondsToStringReturn = [NSString stringWithFormat:@"%i:%02d:%02d",hours,minutes,seconds];
        else
            secondsToStringReturn = [NSString stringWithFormat:@"%02d:%02d:%02d",hours,minutes, seconds];
    }
    else
        secondsToStringReturn = [NSString stringWithFormat:@"%i:%02d", minutes, seconds];
    return secondsToStringReturn;
}

@end
