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


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
