//
//  AlbumTableViewFormatter.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Album.h"
#import "Artist.h"
#import "PreferredFontSizeUtility.h"

@interface AlbumTableViewFormatter : NSObject

+ (NSAttributedString *)formatAlbumLabelUsingAlbum:(Album *)anAlbumInstance;
+ (void)formatAlbumDetailLabelUsingAlbum:(Album *)anAlbumInstance andCell:(UITableViewCell **)aCell;

+ (float)preferredAlbumCellHeight;
+ (CGSize)preferredAlbumAlbumArtSize;

+ (float)nonBoldAlbumLabelFontSize;
+ (BOOL)albumNameIsBold;

@end
