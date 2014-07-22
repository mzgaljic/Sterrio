//
//  ArtistTableViewFormatter.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Artist.h"
#import "PreferredFontSizeUtility.h"

@interface ArtistTableViewFormatter : NSObject

+ (NSAttributedString *)formatArtistLabelUsingArtist:(Artist *)anArtistInstance;
+ (void)formatArtistDetailLabelUsingArtist:(Artist *)anArtistInstance andCell:(UITableViewCell **)aCell;

+ (float)preferredArtistCellHeight;

+ (float)nonBoldArtistLabelFontSize;
+ (BOOL)artistNameIsBold;

@end
