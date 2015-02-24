//
//  FetchVideoInfoOperation.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/21/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "FetchVideoInfoOperation.h"

@interface FetchVideoInfoOperation ()
{
    BOOL _isExecuting;
    BOOL _isFinished;
    Song *aSong;
    NSURL *currentItemLink;
    void *operationQueueKey;
}
@end
@implementation FetchVideoInfoOperation

- (id)initWithSong:(Song *)theSong;
{
    if([super init]){
        _isExecuting = NO;
        _isFinished = NO;
        aSong = theSong;
    }
    return self;
}

- (void)start
{
    if ([self isCancelled]){
        NSLog(@"operation cancelled");
        return;
    }
    //check if any of my dependancies were cancelled. In such an event, cancel this operation as well.
    for(int i = 0; i < self.dependencies.count; i++){
        if([self.dependencies[i] isCancelled]){
            [self isCancelled];
            NSLog(@"operation cancelled");
            return;

        }
    }
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    
    NSLog(@"Starting FetchVideoInfo Operation");
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    __weak NSString *weakId = aSong.youtube_id;
    __weak PlayerView *weakPlayerView = [MusicPlaybackController obtainRawPlayerView];
    __weak SongPlayerCoordinator *weakCoordinator = [SongPlayerCoordinator sharedInstance];
    __weak FetchVideoInfoOperation *weakSelf = self;
    
#warning actually check if we are on wifi.
    BOOL usingWifi = YES;
    BOOL allowedToPlayVideo = YES;
    
    if ([self isCancelled]){
        [self finishBecauseOfCancel];
        return;
    }
    
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:weakId completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
        //NOTE: the MusicPlaybackController methods called from this completion block have
        //been made thread safe.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            if ([weakSelf isCancelled]){
                [weakSelf finish];
                return;
            }
            
            if ([weakSelf isCancelled]){
                [weakSelf finishBecauseOfCancel];
                return;
            }
            if (video)
            {
                //find video quality closest to setting preferences
                NSURL *url;
                if(usingWifi){
                    short maxDesiredQuality = [AppEnvironmentConstants preferredWifiStreamSetting];
                    url =[MusicPlaybackController closestUrlQualityMatchForSetting:maxDesiredQuality usingStreamsDictionary:video.streamURLs];
                }else{
                    short maxDesiredQuality = [AppEnvironmentConstants preferredCellularStreamSetting];
                    url =[MusicPlaybackController closestUrlQualityMatchForSetting:maxDesiredQuality usingStreamsDictionary:video.streamURLs];
                }
                currentItemLink = url;
            }
            /*
             else
             {
             NetworkStatus internetStatus = [reachability currentReachabilityStatus];
             allowSongDidFinishToExecute = YES;
             if (internetStatus == NotReachable){
             [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotConnectToYouTube];
             [MusicPlaybackController playbackExplicitlyPaused];
             [MusicPlaybackController pausePlayback];
             return;
             } else{
             //video may no longer exist, or the internet connection is very weak
             [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotLoadVideo];
             [MusicPlaybackController skipToNextTrack];
             return;
             }
             }
             */
            if ([weakSelf isCancelled]){
                [weakSelf finishBecauseOfCancel];
                return;
            }
            AVURLAsset *asset = [AVURLAsset assetWithURL: currentItemLink];
            
            if(! asset.playable){
                //error initializing video with the url given. Notify user (and perhaps
                //determine the cause...ie: vevo video, video no longer exists, etc)
#warning implementation needed
            }
            
            if(allowedToPlayVideo && video != nil && asset.playable){
                if ([weakSelf isCancelled]){
                    [weakSelf finishBecauseOfCancel];
                    return;
                }
                [weakCoordinator enablePlayerAgain];
                AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
                //allowSongDidFinishToExecute = YES;
                MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    // update the UI here
                    [player begingLoadingPlayerWithPlayerItem:playerItem];
                }];
                
                [weakSelf finish];  //cleans up this operation and marks it as finished.
            } else{
                if ([weakSelf isCancelled]){
                    [weakSelf finishBecauseOfCancel];
                    return;
                }
                /*
                 [MyAlerts displayAlertWithAlertType:ALERT_TYPE_LongVideoSkippedOnCellular];
                 //[weakSelf dismissAllSpinnersForView:weakPlayerView];
                 
                 dispatch_async(dispatch_get_main_queue(), ^(void){
                 //Run UI Updates
                 [weakSelf songDidFinishPlaying:nil];  //triggers the next song to play (for whatever reason/error) in the correct direction
                 });
                 */
            }
        });
    }];
}

- (void)finish
{
    NSLog(@"Ending FetchVideoInfo Operation");
    [self cleanupBeforeFinishedOrCancelled];
    //operation will now be removed from the queue once this returns
}

- (void)finishBecauseOfCancel
{
    NSLog(@"Cancelling FetchVideoInfo Operation");
    [self cleanupBeforeFinishedOrCancelled];
}

- (void)cleanupBeforeFinishedOrCancelled
{
    aSong = nil;
    currentItemLink = nil;
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    _isExecuting = NO;
    _isFinished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

@end
