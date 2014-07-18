//
//  SongTableViewFormatter.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/18/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"
#import "AppEnvironmentConstants.h"

@interface SongTableViewFormatter : NSObject

+ (NSAttributedString *)formatSongLabelUsingSong:(Song *)aSongInstance;
+ (void)formatSongDetailLabelUsingSong:(Song *)aSongInstance andCell:(UITableViewCell **)aCell;


+ (BOOL)songNameIsBold;
+ (float)preferredSongCellHeight;
+ (CGSize)preferredSongAlbumArtSize;

+ (float)songLabelFontSize;
+ (BOOL)songNameIsBold;

@end
