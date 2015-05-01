//
//  PreferredFontSizeUtility.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppEnvironmentConstants.h"

@interface PreferredFontSizeUtility : NSObject

+ (float)actualLabelFontSizeFromCurrentPreferredSize;
+ (float)hypotheticalLabelFontSizeForPreferredSize:(int)aSongCellHeight;
+ (float)actualDetailLabelFontSizeFromCurrentPreferredSize;

@end
