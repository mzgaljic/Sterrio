//
//  UIColor+Strings.h
//  Sterrio
//
//  Created by Mark Zgaljic on 3/24/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 Useful class that lets you easily save a UIColor in NSUserDefaults as an NSString. It's also space
 efficient, unlike other hacks.
 */
@interface UIColor (Strings)

- (NSString *)stringFromColor;
- (NSString *)hexStringFromColor;

+ (UIColor *)colorWithString:(NSString *)stringToConvert;
+ (UIColor *)colorWithHexString:(NSString *)stringToConvert;

@end
