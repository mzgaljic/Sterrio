//
//  LQAlbumArtBackgroundUpdater.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/18/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LQAlbumArtBackgroundUpdater : NSObject

+ (void)beginWaitingForEfficientMomentsToUpdateAlbumArt;
+ (void)forceCheckIfItsAnEfficientTimeToUpdateAlbumArt;

+ (void)downloadHqAlbumArtWhenConvenientForSongId:(NSString *)songId;

@end
