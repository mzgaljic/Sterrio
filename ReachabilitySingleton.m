//
//  ReachabilitySingleton.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/21/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "ReachabilitySingleton.h"
#import <AVFoundation/AVAudioPlayer.h>
#import "AppEnvironmentConstants.h"
#import "MusicPlaybackController.h"


typedef NS_ENUM(NSUInteger, Connection_Type) {
    Connection_Type_Wifi,
    Connection_Type_Cellular,
    Connection_Type_None
};

typedef NS_ENUM(NSUInteger, Connection_State){
    Connection_State_Connected,
    Connection_State_Disconnected
};

@interface ReachabilitySingleton ()
{
    Reachability *reachability;
}
@property(nonatomic, strong) NSNotificationCenter *notifCenter;
@property(nonatomic, assign) Connection_Type connectionType;
@property(nonatomic, assign) Connection_State connectionState;
@end

@implementation ReachabilitySingleton

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    if(self = [super init]){
        reachability = [Reachability reachabilityForInternetConnection];
        //3G,EDGE,CDMA does count as "reachable". Reachable as long as we are connected somehow.
        reachability.reachableOnWWAN = YES;
        
        self.notifCenter = [NSNotificationCenter defaultCenter];
        [self setupBlocks];
        [self initEnumStates];
        [reachability startNotifier];
    }
    return self;
}

- (BOOL)isConnectedToWifi
{
    return (self.connectionType == Connection_Type_Wifi);
}
- (BOOL)isConnectedToCellular
{
    return (self.connectionType == Connection_Type_Cellular);
}
- (BOOL)isConnectedToInternet
{
    return (self.connectionState == Connection_State_Connected);
}
- (BOOL)isConnectionCompletelyGone
{
    return (self.connectionState == Connection_State_Disconnected);
}

- (void)setupBlocks
{
    __weak __block typeof(self) weakself = self;
    
    reachability.reachableBlock = ^(Reachability*reach)
    {
        //conected to internet
        weakself.connectionState = Connection_State_Connected;
        if([reach isReachableViaWiFi])
            weakself.connectionType = Connection_Type_Wifi;
        else{
            weakself.connectionType = Connection_Type_Cellular;
            if([ReachabilitySingleton shouldShowCelluarStreamingWarning]){
                   [ReachabilitySingleton handleNeedToShowCellularDataWarning];
            }
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [weakself.notifCenter postNotificationName:MZReachabilityStateChanged
                                                object:nil];
        }];
    };
    reachability.unreachableBlock = ^(Reachability*reach)
    {
        //not connected to internet
        weakself.connectionState = Connection_State_Disconnected;
        weakself.connectionType = Connection_Type_None;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [weakself.notifCenter postNotificationName:MZReachabilityStateChanged
                                                object:nil];
        }];
    };
}

+ (void)showCellularStreamingWarningIfApplicable
{
    safeSynchronousDispatchToMainQueue(^{
        if([ReachabilitySingleton shouldShowCelluarStreamingWarning]) {
            [ReachabilitySingleton handleNeedToShowCellularDataWarning];
        }
    });
}

//---- Utils ----
+ (void)handleNeedToShowCellularDataWarning
{
    [MyAlerts displayAlertWithAlertType:ALERT_TYPE_WarnUserOfCellularDataFees];
    [AppEnvironmentConstants setUserHasSeenCellularDataUsageWarning:YES];
    [[NSUserDefaults standardUserDefaults] setBool:YES
                                            forKey:USER_HAS_SEEN_CELLULAR_WARNING];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)shouldShowCelluarStreamingWarning
{
    return (! [AppEnvironmentConstants didPreviouslyShowUserCellularWarning]
            && ([ReachabilitySingleton isUserPreviewingAndPlayerPlaying]
                || [ReachabilitySingleton isMainPlayerPlaying]));
}

+ (BOOL)isUserPreviewingAndPlayerPlaying
{
    return ([AppEnvironmentConstants isUserPreviewingAVideo]
            && [AppEnvironmentConstants currrentPreviewPlayerState] == PREVIEW_PLAYBACK_STATE_Playing);
}

+ (BOOL)isMainPlayerPlaying
{
    __block BOOL retval;
    //obtainRawAVPlayer call is NOT thread safe, using main thread...
    safeSynchronousDispatchToMainQueue(^{
        AVPlayer *player = [MusicPlaybackController obtainRawAVPlayer];
        retval = ([NowPlayingSong sharedInstance].nowPlayingItem != nil
                  && player.rate > 0);
    });
    return retval;
}

- (void)initEnumStates
{
    if([reachability isReachableViaWiFi]){
        self.connectionType = Connection_Type_Wifi;
        self.connectionState = Connection_State_Connected;
    }
    else if([reachability isReachableViaWWAN]){
        self.connectionType = Connection_Type_Cellular;
        self.connectionState = Connection_State_Connected;
    }
    else{
        self.connectionType = Connection_Type_None;
        self.connectionState = Connection_State_Disconnected;
    }
}

@end
