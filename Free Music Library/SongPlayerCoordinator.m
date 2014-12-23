//
//  SongPlayerCoordinator.m
//  Muzic
//
//  Created by Mark Zgaljic on 12/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "SongPlayerCoordinator.h"

@interface SongPlayerCoordinator ()
{
    //for key value observing
    id timeObserver;
    int totalVideoDuration;
    int mostRecentLoadedDuration;
}
@end

@implementation SongPlayerCoordinator
@synthesize delegate = _delegate;

//key value observing (AVPlayer)
void *kCurrentItemDidChangeKVO  = &kCurrentItemDidChangeKVO;
void *kRateDidChangeKVO         = &kRateDidChangeKVO;
void *kStatusDidChangeKVO       = &kStatusDidChangeKVO;
void *kDurationDidChangeKVO     = &kDurationDidChangeKVO;
void *kTimeRangesKVO            = &kTimeRangesKVO;
void *kBufferFullKVO            = &kBufferFullKVO;
void *kBufferEmptyKVO           = &kBufferEmptyKVO;
void *kDidFailKVO               = &kDidFailKVO;

#pragma mark - Class lifecycle stuff
+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (void)dealloc
{
    [[MusicPlaybackController obtainRawAVPlayer] removeTimeObserver:timeObserver];
    //singleton should never be released
    abort();
}

#pragma mark - Other
- (void)setDelegate:(id<VideoPlayerControlInterfaceDelegate>)theDelegate
{
    _delegate = theDelegate;
}

- (void)setupKeyvalueObservers
{
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    
    [player addObserver:self
             forKeyPath:@"rate"
                options:NSKeyValueObservingOptionNew
                context:kRateDidChangeKVO];
    [player addObserver:self
             forKeyPath:@"currentItem.status"
                options:NSKeyValueObservingOptionNew
                context:kStatusDidChangeKVO];
    [player addObserver:self
             forKeyPath:@"currentItem.duration"
                options:NSKeyValueObservingOptionNew
                context:kDurationDidChangeKVO];
    [player addObserver:self
             forKeyPath:@"currentItem.loadedTimeRanges"
                options:NSKeyValueObservingOptionNew
                context:kTimeRangesKVO];
    [player addObserver:self
             forKeyPath:@"currentItem.playbackBufferFull"
                options:NSKeyValueObservingOptionNew
                context:kBufferFullKVO];
    [player addObserver:self
             forKeyPath:@"currentItem.playbackBufferEmpty"
                options:NSKeyValueObservingOptionNew
                context:kBufferEmptyKVO];
    [player addObserver:self
             forKeyPath:@"currentItem.error"
                options:NSKeyValueObservingOptionNew
                context:kDidFailKVO];
    
    //[MusicPlaybackController resumePlayback];  //starts playback
    
    timeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.1, 100) queue:nil usingBlock:^(CMTime time) {
        //code will be called each 1/10th second....  NSLog(@"Playback time %.5f", CMTimeGetSeconds(time));
        [_delegate updatePlaybackTimeSlider];
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
    if (kRateDidChangeKVO == context) {
        float rate = player.rate;
        BOOL internetConnectionPresent;
        BOOL videoCompletelyBuffered = (mostRecentLoadedDuration == totalVideoDuration);
        
        Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
        if ([networkReachability currentReachabilityStatus] == NotReachable)
            internetConnectionPresent = NO;
        else
            internetConnectionPresent = YES;
        
        if(rate != 0 && mostRecentLoadedDuration != 0 &&internetConnectionPresent){  //playing
            NSLog(@"Playing");
            
        } else if(rate == 0 && !videoCompletelyBuffered &&!internetConnectionPresent){  //stopped
            //Playback has stopped due to an internet connection issue.
            NSLog(@"Video stopped, no connection.");
            
        }else{  //paused
            NSLog(@"Paused");
        }
        
    } else if (kStatusDidChangeKVO == context) {
        //player "status" has changed. Not particulary useful information.
        if (player.status == AVPlayerStatusReadyToPlay) {
            NSArray * timeRanges = player.currentItem.loadedTimeRanges;
            if (timeRanges && [timeRanges count]){
                CMTimeRange timerange = [[timeRanges objectAtIndex:0] CMTimeRangeValue];
                int secondsBuffed = (int)CMTimeGetSeconds(CMTimeAdd(timerange.start, timerange.duration));
                if(secondsBuffed > 0){
                    NSLog(@"Min buffer reached, ready to continue playing.");
                }
            }
        }
        
    } else if (kTimeRangesKVO == context) {
        NSArray *timeRanges = (NSArray *)[change objectForKey:NSKeyValueChangeNewKey];
        if (timeRanges && [timeRanges count]) {
            CMTimeRange timerange = [[timeRanges objectAtIndex:0] CMTimeRangeValue];
            
            int secondsLoaded = (int)CMTimeGetSeconds(CMTimeAdd(timerange.start, timerange.duration));
            if(secondsLoaded == mostRecentLoadedDuration)
                return;
            else
                mostRecentLoadedDuration = secondsLoaded;
            
            //NSLog(@"New loaded range: %i -> %i", (int)CMTimeGetSeconds(timerange.start), secondsLoaded);
            
            //if paused, check if user wanted it paused. if not, resume playback since buffer is back
            if(!(player.rate == 1) && ![MusicPlaybackController playbackExplicitlyPaused]){
                [MusicPlaybackController resumePlayback];
            }
        }
    }
}

- (void)beginShrinkingVideoPlayer
{
#warning unimplemented. Shrink player here.
}


@end
