//
//  MZAlbumSectionHeader.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/24/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Album.h"
#import "Song.h"
#import "AlbumArtUtilities.h"
#import "UIImage+colorImages.h"
#import "AppEnvironmentConstants.h"

@interface MZAlbumSectionHeader : UIView <UITextFieldDelegate>

- (instancetype)initWithFrame:(CGRect)frame album:(Album *)anAlbum;

@end
