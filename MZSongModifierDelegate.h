//
//  MZSongModifierDelegate.h
//  Muzic
//
//  Created by Mark Zgaljic on 1/21/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MZSongModifierDelegate <NSObject>

- (void)pushThisVC:(UIViewController *)vc;
- (void)performCleanupBeforeSongIsSaved:(Song *)newLibSong;

@end
