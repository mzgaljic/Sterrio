//
//  MZAppTheme.h
//  Sterrio
//
//  Created by Mark Zgaljic on 3/24/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MZAppTheme : NSObject
@property (nonatomic, strong, readonly) UIColor *mainGuiTint;
@property (nonatomic, strong, readonly) UIColor *contrastingTextOrNavBarTint;

- (instancetype)initWithMainGuiTint:(UIColor *)mainGuiColor
         constrastingTextOrNavColor:(UIColor *)contrastingColor;
- (instancetype)initWithNsUserDefaultsCompatibleDict:(NSDictionary *)dict;
- (NSDictionary *)nsUserDefaultsCompatibleDictFromTheme;

- (BOOL)equalToAppTheme:(MZAppTheme *)anotherTheme;

+ (MZAppTheme *)defaultAppThemeBeforeUserPickedTheme;
+ (UIColor *)expandingCellGestureInitialColor;
+ (UIColor *)expandingCellGestureQueueItemColor;
+ (UIColor *)expandingCellGestureDeleteItemColor;
+ (UIColor *)nowPlayingItemColor;
+ (NSArray *)allAppThemes;
+ (NSString *)nsUserDefaultsKeyAppThemeDict;

@end
