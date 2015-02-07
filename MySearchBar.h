//
//  MySearchBar.h
//  Muzic
//
//  Created by Mark Zgaljic on 1/3/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImage+colorImages.h"
#import "UIColor+LighterAndDarker.h"
#import "SongTableViewFormatter.h"

@interface MySearchBar : UISearchBar
- (id)initWithFrame:(CGRect)frame placeholderText:(NSString *)text;

- (void)updateFontSizeIfNecessary;

@end
