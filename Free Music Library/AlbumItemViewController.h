//
//  AlbumItemViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlbumItemViewController : UIViewController
@property (strong, nonatomic) NSString *albumNameTitle;
@property (strong, nonatomic) UIImage *albumImage;

//GUI vars
@property (weak, nonatomic) IBOutlet UILabel *albumNameTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *albumUiImage;
@property (weak, nonatomic) IBOutlet UITableView *albumSongsTableView;

@end
