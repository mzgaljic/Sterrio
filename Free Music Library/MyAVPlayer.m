//
//  MyAVPlayer.m
//  Muzic
//
//  Created by Mark Zgaljic on 10/17/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MyAVPlayer.h"


@interface MyAVPlayer ()
{
    AVPlayerItem *playerItem;
    NSURL *currentItemLink;
    BOOL movingForward;  //identifies which direction the user just went (back/forward) in queue
    
    NSString * NEW_SONG_IN_AVPLAYER;
    NSString * AVPLAYER_DONE_PLAYING;
}
@end

@implementation MyAVPlayer


- (id)init
{
    if(self = [super init]){
        NEW_SONG_IN_AVPLAYER = @"New song added to AVPlayer, lets hope the interface makes appropriate changes.";
        AVPLAYER_DONE_PLAYING = @"Avplayer has no more items to play.";
        movingForward = YES;
        currentItemLink = nil;
        playerItem = self.currentItem;
        
        [self begingListeningForNotifications];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startPlaybackOfSong:(Song *)aSong goingForward:(BOOL)yes
{
    movingForward = yes;
    [self playSong:aSong];
}

- (void)begingListeningForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(songDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
}

//Will be called when YTVideoAvPlayer finishes playing a YTVideoPlayerItem
- (void)songDidFinishPlaying:(NSNotification *) notification
{
    NSLog(@"Playback of song finished.");
    if([MusicPlaybackController listOfUpcomingSongsInQueue].count > 0){  //more songs in queue
        if(movingForward)
            [MusicPlaybackController skipToNextTrack];
        else
            [MusicPlaybackController returnToPreviousTrack];
    }
    else{  //last song just ended
        [MusicPlaybackController explicitlyPausePlayback:YES];
        [MusicPlaybackController pausePlayback];
    }
}

- (void)playSong:(Song *)aSong
{
    __weak NSString *weakId = aSong.youtube_id;
    __weak Song *weakSong = aSong;
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:weakId completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
        BOOL allowedToPlayVideo = NO;  //not checking if we can physically play, but legally (Apple's 10 minute streaming rule)
        if (video)
        {
            BOOL usingWifi = NO;
            Reachability *reachability = [Reachability reachabilityForInternetConnection];
            [reachability startNotifier];
            NetworkStatus status = [reachability currentReachabilityStatus];
            if (status == ReachableViaWiFi){
                //WiFi
                allowedToPlayVideo = YES;
                usingWifi = YES;
            }
            else if (status == ReachableViaWWAN)
            {
                //3G
                if(video.duration >= 600)  //user cant watch video longer than 10 minutes without wifi
                    allowedToPlayVideo = NO;
                else
                    allowedToPlayVideo = YES;
            }
            if(allowedToPlayVideo){
                //find video quality closest to setting preferences
                NSDictionary *vidQualityDict = video.streamURLs;
                NSURL *url;
                if(usingWifi){
                    short maxDesiredQuality = [AppEnvironmentConstants preferredWifiStreamSetting];
                    url =[MusicPlaybackController closestUrlQualityMatchForSetting:maxDesiredQuality usingStreamsDictionary:vidQualityDict];
                    
                }else{
                    short maxDesiredQuality = [AppEnvironmentConstants preferredCellularStreamSetting];
                    url =[MusicPlaybackController closestUrlQualityMatchForSetting:maxDesiredQuality usingStreamsDictionary:vidQualityDict];
                }
                
                currentItemLink = url;
            }
            else{
                NSLog(@"Skipping song since it is > 10 min (on Cellular network)");
                
                //NSString *title = @"Long Video Without Wifi";
                //NSString *msg = @"Sorry, playback of long videos (ie: more than 10 minutes) is restricted to Wifi.";
                //[self launchAlertViewWithDialogUsingTitle:title andMessage:msg];
            }
        }
        else
        {
            NSLog(@"Error has occured loading video. Skipping to next track instead.");
            // Handle error
            //NSString *title = @"Trouble Loading Video";
            //NSString *msg = @"Sorry, there was a problem. Please try again.";
            //[self launchAlertViewWithDialogUsingTitle:title andMessage:msg];
        }
        
        if(allowedToPlayVideo && video != nil){
            playerItem = [AVPlayerItem playerItemWithURL: currentItemLink];
            [self replaceCurrentItemWithPlayerItem:playerItem];
            
            //posting notifications about important AVPLayerItem changes. GUI should react appropriately where needed.
            [[NSNotificationCenter defaultCenter] postNotificationName:NEW_SONG_IN_AVPLAYER object:weakSong];
            [[NSNotificationCenter defaultCenter] postNotificationName:AVPLAYER_DONE_PLAYING object:nil];
            [self play];
        } else{
            currentItemLink = nil;
            playerItem = nil;
            [self songDidFinishPlaying:nil];  //triggers the next song to play (for whatever reason/error)
        }
    }];
}

- (void)launchAlertViewWithDialogUsingTitle:(NSString *)title andMessage:(NSString *)msg
{
    SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:title
                                                      message:msg
                                                     delegate:self
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    
    alert.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    alert.messageLabelFont = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize]];
    alert.suggestedButtonFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    [alert show];
}

@end
