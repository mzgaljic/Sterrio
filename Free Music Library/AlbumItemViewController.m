//
//  AlbumItemViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AlbumItemViewController.h"

@interface AlbumItemViewController ()
@end

@implementation AlbumItemViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setUpAlbumView];
}

- (void)setUpAlbumView
{
    self.albumNameTitleLabel.text = self.album.albumName;
    self.albumUiImageView.image = [self albumArtFileNameToUiImage:self.album.albumArtFileName];
    self.navBar.title = self.album.albumName;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *)albumArtFileNameToUiImage:(NSString *)albumArtFileName
{
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                            NSUserDomainMask, YES) objectAtIndex:0];
    NSString* path = [docDir stringByAppendingPathComponent: albumArtFileName];
    return [UIImage imageWithContentsOfFile:path];
}

@end