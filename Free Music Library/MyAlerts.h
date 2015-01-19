//
//  MyAlerts.h
//  Muzic
//
//  Created by Mark Zgaljic on 12/31/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyAlerts : NSObject

typedef enum {
    ALERT_TYPE_CannotConnectToYouTube,
    ALERT_TYPE_FATAL_SONG_DURATION_ERROR,
    ALERT_TYPE_LongVideoSkippedOnCellular,
    
    ALERT_TYPE_TroubleSharingVideo,
    ALERT_TYPE_TroubleSharingLibrarySong
} ALERT_TYPE;

+ (void)displayAlertWithAlertType:(ALERT_TYPE)type;

@end
