//
//  IntroVideoView.m
//  Sterrio
//
//  Created by Mark Zgaljic on 12/20/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import "IntroVideoView.h"
#import "MZPlayer.h"
#import "SongPlayerViewDisplayUtility.h"
#import "AppEnvironmentConstants.h"

@interface IntroVideoView ()
@property (nonatomic, strong) MZPlayer *player;
@end

@implementation IntroVideoView
static int const paddingFromScreenEdge = 25;

- (instancetype)initWithFrame:(CGRect)frame
                        title:(NSString *)title
                  description:(NSString *)desc
                     videoUrl:(NSURL *)url
{
    if(self = [super initWithFrame:frame]) {
        [self helpSetupVideoPlayerWithUrl:url];
        [self helpSetupViewTitle:title];
        [self helpSetupViewDescription:desc];
    }
    return self;
}

- (void)helpSetupViewTitle:(NSString *)titleText
{
    int width = self.frame.size.width;
    int labelHeight = 45;
    int labelY = self.player.frame.origin.y - (labelHeight * 2.5);
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(paddingFromScreenEdge,
                                                               labelY,
                                                               width - (paddingFromScreenEdge * 2),
                                                               labelHeight)];
    title.text = titleText;
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                 size:28];
    title.textColor = [UIColor whiteColor];
    [self addSubview:title];
}

- (void)helpSetupViewDescription:(NSString *)description
{
    int width = self.frame.size.width;
    int height = self.frame.size.height;
    int labelHeight = height / 4;
    int labelY = self.player.frame.origin.y + self.player.frame.size.height + 20;
    UILabel *desc = [[UILabel alloc] initWithFrame:CGRectMake(paddingFromScreenEdge,
                                                              labelY,
                                                              width - (paddingFromScreenEdge * 2),
                                                              labelHeight)];
    desc.text = description;
    desc.numberOfLines = 0;
    desc.textAlignment = NSTextAlignmentCenter;
    desc.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                size:18];
    desc.textColor = [UIColor whiteColor];
    [self addSubview:desc];
}

- (void)helpSetupVideoPlayerWithUrl:(NSURL *)url
{
    int width = self.frame.size.width;
    int height = self.frame.size.height;
    int playerWidth = width - paddingFromScreenEdge;
    int playerHeight = [SongPlayerViewDisplayUtility videoHeightInSixteenByNineAspectRatioGivenWidth:playerWidth];
    

    
    _player = [[MZPlayer alloc] initWithFrame:CGRectMake((width - playerWidth)/2,
                                                         (height/2) - (playerHeight / 1.5),
                                                         playerWidth,
                                                         playerHeight)
                                     videoURL:url
                           useControlsOverlay:NO];
    _player.loopPlaybackForever = YES;
    [_player pause];
    [self addSubview:self.player];
}

- (void)startVideoLooping
{
    [self.player play];
}

- (void)stopPlaybackAndResetToBeginning
{
    [self.player pause];
    //reset beginning
    Float64 beginning = 0.00;
    CMTime targetTime = CMTimeMakeWithSeconds(beginning, NSEC_PER_SEC);
    [self.player.avPlayer seekToTime:targetTime
                     toleranceBefore:kCMTimeZero
                      toleranceAfter:kCMTimeZero];
}

- (void)dealloc
{
    [_player destroyPlayer];
    _player = nil;
}

@end
