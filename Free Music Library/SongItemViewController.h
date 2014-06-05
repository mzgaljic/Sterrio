//
//  SongItemViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SongItemViewController : UIViewController
@property (assign, nonatomic) int songNumberInSongCollection;
@property (assign, nonatomic) int totalSongsInCollection;

@property (strong, nonatomic) NSString *songLabelValue;
@property (strong, nonatomic) NSString *artist_AlbumLabelValue;
//@property (strong, nonatomic) NSString *uri;

//GUI vars
@property (weak, nonatomic) IBOutlet UILabel *songLabel;
@property (weak, nonatomic) IBOutlet UILabel *artist_AlbumLabel;
@property (weak, nonatomic) IBOutlet UILabel *testDiscogs;

@end
