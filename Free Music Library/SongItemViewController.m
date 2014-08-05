//
//  SongItemViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "SongItemViewController.h"

@interface SongItemViewController ()
@end

@implementation SongItemViewController
@synthesize aNewSong, aNewAlbum, aNewArtist, aNewPlaylist, navBar;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        // Do something when in landscape
        
    }
    else
    {
        
        // Do something when in portrait
        float percentOfScreen = screenHeight * .60;  //70%
        //_myWebView = [[UIWebView alloc] initWithFrame :CGRectMake(0, 44, screenWidth, percentOfScreen)];
    }
    

    
    //set song/album details for currently selected song
    NSString *navBarTitle;
    if(self.songNumberInSongCollection == -1){  //could not figure out song #
        navBarTitle = [NSString stringWithFormat:@"%@/%d", @"?", self.totalSongsInCollection];
    } else{
        navBarTitle = [NSString stringWithFormat:@"%d/%d", self.songNumberInSongCollection, self.totalSongsInCollection];
    }
    self.navBar.title = navBarTitle;
    self.songNameLabel.text = self.aNewSong.songName;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = YES;
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
    [imageCache clearDisk];
}

#pragma mark - Playing parsed Youtube video

- (IBAction)buttonTapped:(id)sender
{
    YouTubeVideoSearchService *yt = [[YouTubeVideoSearchService alloc] init];
    [yt searchYouTubeForVideosUsingString:@"cats"];
}
                   
                   
@end
