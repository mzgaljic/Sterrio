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
    CannotConnectToYouTube
} ALERT_TYPE;

+ (void)displayAlertWithAlertType:(ALERT_TYPE)type;

@end
