//
//  MZAppTheme.h
//  Sterrio
//
//  Created by Mark Zgaljic on 3/24/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MZAppTheme : NSObject
@property (nonatomic, strong, readonly) NSString *themeName;
@property (nonatomic, strong, readonly) UIColor *mainGuiTint;
@property (nonatomic, strong, readonly) UIColor *navBarToolbarTextTint;
/** 
 Contrasting text color for a background color that is NOT the same as the main gui tint. 
 Specify this if for example the mainGuiTint is a bright yellow, and it's hard to see on a
 bright background.
 */
@property (nonatomic, strong, readonly) UIColor *contrastingTextColor;
@property (nonatomic, assign, readonly) BOOL useWhiteStatusBar;

- (instancetype)initWithThemeName:(NSString *)name
                      mainGuiTint:(UIColor *)mainGuiColor
                useWhiteStatusBar:(BOOL)whiteStatusBar
            navBarToolbarTextTint:(UIColor *)navBarToolBarTint
             contrastingTextColor:(UIColor *)contrastingColor;

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
