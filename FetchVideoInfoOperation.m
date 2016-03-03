//
//  FetchVideoInfoOperation.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/21/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "FetchVideoInfoOperation.h"
#import "YouTubeService.h"
#import "DeletedYtVideoAlertCreator.h"

@interface FetchVideoInfoOperation ()
{
    BOOL _isExecuting;
    BOOL _isFinished;
    BOOL _isCancelled;
    BOOL allowedToPlayVideo;
    
    NSString *songsYoutubeId;
    NSString *songName;
    NSString *artistName;
    NSManagedObjectID *songObjId;
}
@end
@implementation FetchVideoInfoOperation

- (id)initWithSongsYoutubeId:(NSString *)youtubeId
                    songName:(NSString *)sName
                  artistName:(NSString *)aName
             managedObjectId:(NSManagedObjectID *)objId
{
    if(self = [super init]){
        _isExecuting = NO;
        _isFinished = NO;
        _isCancelled = NO;
        songsYoutubeId = [youtubeId copy];
        songName = [sName copy];
        artistName = [aName copy];
        songObjId = [objId copy];
    }
    return self;
}

- (void)start
{
    if ([self isCancelled]){
        NSLog(@"operation cancelled");
        return;
    }
    
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    
    //check if any of my dependancies were cancelled. In such an event, cancel this operation as well.
    for(int i = 0; i < self.dependencies.count; i++){
        if([self.dependencies[i] isCancelled]){
            [self cancel];
            NSLog(@"operation cancelled");
            return;
        }
        if([self.dependencies[i] isMemberOfClass:[DetermineVideoPlayableOperation class]]){
            DetermineVideoPlayableOperation *completedOperation;
            completedOperation = (DetermineVideoPlayableOperation *)self.dependencies[i];
            
            NSAssert([completedOperation respondsToSelector:@selector(allowedToPlayVideo)], @"allowedToPlayVideo var is not being passed between NSOperations anymore.");
            allowedToPlayVideo = [completedOperation performSelector:@selector(allowedToPlayVideo)
                                                          withObject:nil];
        }
    }
    
    if(allowedToPlayVideo == NO){
        NSLog(@"operation cancelled");
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MZStartBackgroundTaskHandlerIfInactive
                                                        object:nil];
    
    NSLog(@"Starting FetchVideoInfo Operation");
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    if([[ReachabilitySingleton sharedInstance] isConnectionCompletelyGone]){
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotConnectToYouTube];
        [MusicPlaybackController playbackExplicitlyPaused];
        [MusicPlaybackController pausePlayback];
        MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
        [player dismissAllSpinners];
        [self finishBecauseOfCancel];
        return;
    }
    
    __weak NSString *weakId = songsYoutubeId;
    __weak NSString *weakSongName = songName;
    __weak NSString *weakArtistName = artistName;
    __weak NSManagedObjectID *weakSongObjId = songObjId;
    
    __weak SongPlayerCoordinator *weakCoordinator = [SongPlayerCoordinator sharedInstance];
    __weak FetchVideoInfoOperation *weakSelf = self;
    
    BOOL usingWifi = [[ReachabilitySingleton sharedInstance] isConnectedToWifi];
    
    if ([self isCancelled]){
        [self finishBecauseOfCancel];
        return;
    }
    
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:weakId completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
        if([NSThread isMainThread]) {
            NSLog(@"block returns on main thread!!");
        }
        if(error.code == 150) {
            [DeletedYtVideoAlertCreator createVideoDeletedAlertWithYtVideoId:weakId
                                                                        name:weakSongName
                                                                  artistName:weakArtistName
                                                             managedObjectId:weakSongObjId];
            [MusicPlaybackController playbackExplicitlyPaused];
            [MusicPlaybackController pausePlayback];
            MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
            [player dismissAllSpinners];
            [weakSelf finishBecauseOfCancel];
            return;
            
        } else if([[ReachabilitySingleton sharedInstance] isConnectionCompletelyGone]){
            [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotConnectToYouTube];
            [MusicPlaybackController playbackExplicitlyPaused];
            [MusicPlaybackController pausePlayback];
            MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
            [player dismissAllSpinners];
            [weakSelf finishBecauseOfCancel];
            return;
        }
        
        //NOTE: the MusicPlaybackController methods called from this completion block have
        //been made thread safe.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            NSURL *currentItemLink;
            
            if ([weakSelf isCancelled]){
                [weakSelf finishBecauseOfCancel];
                return;
            }
            else if(video)
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
            } else {
                ReachabilitySingleton *reachability = [ReachabilitySingleton sharedInstance];
                if([reachability isConnectionCompletelyGone]){
                    [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotConnectToYouTube];
                    [MusicPlaybackController playbackExplicitlyPaused];
                    [MusicPlaybackController pausePlayback];
                    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
                    [player dismissAllSpinners];
                    [weakSelf finishBecauseOfCancel];
                    return;
                } else{
                    //video may no longer exist, or the internet connection is very weak
                    BOOL exists = [YouTubeService doesVideoStillExist:weakId];
                    if(exists) {
                        //looks like some videos may not be loading properly anymore.
                        NSString *eventName = @"Unexplained Video Load Failure. ID attached.";
                        [Answers logCustomEventWithName:eventName
                                       customAttributes:@{@"YouTube ID" : weakId}];
                        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_SomeVideosNoLongerLoading];
                    } else {
                        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotLoadVideo];
                    }
                    
                    //[MusicPlaybackController skipToNextTrack];
                    [weakSelf finishBecauseOfCancel];
                    return;
                }
            }
            if ([weakSelf isCancelled]){
                [weakSelf finishBecauseOfCancel];
                return;
            }
            
            //before creating asset, make sure the internet is still active
            if([[ReachabilitySingleton sharedInstance] isConnectionCompletelyGone]){
                [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotConnectToYouTube];
                [MusicPlaybackController playbackExplicitlyPaused];
                [MusicPlaybackController pausePlayback];
                MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
                [player dismissAllSpinners];
                [weakSelf finishBecauseOfCancel];
                return;
            }
            
            AVURLAsset *asset = [AVURLAsset assetWithURL: currentItemLink];
            
            if(allowedToPlayVideo && video != nil){
                MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
                [player allowSongDidFinishNotificationToProceed:YES];
                if ([weakSelf isCancelled]){ 
                    [weakSelf finishBecauseOfCancel];
                    return;
                }
                [weakCoordinator enablePlayerAgain];
                __block AVPlayerItem *weakPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    // update the UI here
                    [VideoPlayerWrapper beginPlaybackWithPlayerItem:weakPlayerItem];
                }];
                
                [weakSelf finish];  //cleans up this operation and marks it as finished.
            } else{
                if ([weakSelf isCancelled]){
                    [weakSelf finishBecauseOfCancel];
                    return;
                }
                //something went wrong, one of the conditions failed. maybe it is the internet.
                //before creating asset, make sure the internet is still active
                if([[ReachabilitySingleton sharedInstance] isConnectionCompletelyGone]){
                    [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotConnectToYouTube];
                    [MusicPlaybackController playbackExplicitlyPaused];
                    [MusicPlaybackController pausePlayback];
                    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
                    [player dismissAllSpinners];
                    [weakSelf finishBecauseOfCancel];
                    return;
                } else{
                    //tells user "dont know why song could not load..."
                    [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotLoadVideo];
                    [MusicPlaybackController playbackExplicitlyPaused];
                    [MusicPlaybackController pausePlayback];
                    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
                    [player dismissAllSpinners];
                    [weakSelf finishBecauseOfCancel];
                    return;
                }
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
    songsYoutubeId = nil;
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isCancelled"];
    _isExecuting = NO;
    _isFinished = YES;
    _isCancelled = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isCancelled"];
}

@end
