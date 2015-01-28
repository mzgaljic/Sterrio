//
//  UIDevice+DeviceName.h
//  Muzic
//
//  Created by Mark Zgaljic on 12/31/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (DeviceName)

+ (NSString *)deviceName;
+ (NSString *)appBuildString;
+ (NSString *)appVersionString;

@end
