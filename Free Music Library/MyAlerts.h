//
//  MyAlerts.h
//  Muzic
//
//  Created by Mark Zgaljic on 12/31/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFDropdownNotification.h"

@interface MyAlerts : NSObject

typedef enum {
    ALERT_TYPE_CannotConnectToYouTube,   //show mesage under all VC's
    ALERT_TYPE_CannotLoadVideo,       //irrelevant
    
    ALERT_TYPE_FatalSongDurationError,   //irrelevant
    ALERT_TYPE_PotentialVideoDurationFetchFail,
    ALERT_TYPE_LongVideoSkippedOnCellular,
    ALERT_TYPE_LongPreviewVideoSkippedOnCellular,   //irrelavent. shouldnt even allow user to start preview on cellular.
    
    ALERT_TYPE_TroubleSharingVideo,   //should be simple alert view
    ALERT_TYPE_TroubleSharingLibrarySong,  //simple alert view
    
    ALERT_TYPE_CannotOpenSafariError,      //simple alert view
    
    ALERT_TYPE_CannotOpenSelectedImageError,   //simple alert view
    
    ALERT_TYPE_SongSaveHasFailed,     //simple alert view
    
    ALERT_TYPE_SongQueued     //really quick auto-dismissed alert.
} ALERT_TYPE;

+ (void)displayAlertWithAlertType:(ALERT_TYPE)type;

@end
