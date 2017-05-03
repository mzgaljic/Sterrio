//
//  EditableSongDataSourceDelegate.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/15/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EditableSongDataSourceDelegate <NSObject>
- (void)performEditSegueWithSong:(Song *)songToBeEdited;
@end