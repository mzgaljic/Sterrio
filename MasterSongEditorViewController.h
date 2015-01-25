//
//  MasterSongEditorViewController.h
//  Muzic
//
//  Created by Mark Zgaljic on 1/25/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyViewController.h"
#import "MZSongModifierTableView.h"
#import "MZSongModifierDelegate.h"

@interface MasterSongEditorViewController : MyViewController <MZSongModifierDelegate>

@property (nonatomic, strong) Song *songIAmEditing;

- (void)pushThisVC:(UIViewController *)vc;
- (void)performCleanupBeforeSongIsSaved:(Song *)newLibSong;

@end
