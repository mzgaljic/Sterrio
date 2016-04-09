//
//  MZAppTheme.m
//  Sterrio
//
//  Created by Mark Zgaljic on 3/24/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZAppTheme.h"
#import "UIColor+Strings.h"
#import "UIColor+LighterAndDarker.h"
#import "AppEnvironmentConstants.h"

@interface MZAppTheme ()
@property (nonatomic, strong, readwrite) NSString *themeName;
@property (nonatomic, strong, readwrite) UIColor *mainGuiTint;
@property (nonatomic, strong, readwrite) UIColor *navBarToolbarTextTint;
@property (nonatomic, strong, readwrite) UIColor *contrastingTextColor;
@property (nonatomic, assign, readwrite) BOOL useWhiteStatusBar;
@end

@implementation MZAppTheme
#define Rgb2UIColor(r, g, b, a)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:(a)]
NSString * const MZAppThemeNameKey = @"App Theme name";
NSString * const MZAppThemeMainGuiColorKey = @"Main Gui Tint";
NSString * const MZAppThemeUseWhiteStatusBarKey = @"use a white status bar color";
NSString * const MZAppThemeNavBarToolBarTextTintKey = @"text of nav bar and toolbar text";
NSString * const MZAppThemeContrastingTextColor = @"contrasting text color";

NSString * const MZDefaultAppThemeSunriseOrange = @"Sunrise Orange";


- (instancetype)initWithThemeName:(NSString *)name
                      mainGuiTint:(UIColor *)mainGuiColor
                     useWhiteStatusBar:(BOOL)whiteStatusBar
              navBarToolbarTextTint:(UIColor *)navBarToolBarTint
               contrastingTextColor:(UIColor *)contrastingColor
{
    if(self = [super init]) {
        _themeName = name;
        _mainGuiTint = mainGuiColor;
        _useWhiteStatusBar = whiteStatusBar;
        _navBarToolbarTextTint = navBarToolBarTint;
        _contrastingTextColor = contrastingColor;
    }
    return self;
}

- (instancetype)initWithNsUserDefaultsCompatibleDict:(NSDictionary *)dict;
{
    if(self = [super init]) {
        _themeName = [dict objectForKey:MZAppThemeNameKey];
        _mainGuiTint = [UIColor colorWithString:[dict objectForKey:MZAppThemeMainGuiColorKey]];
        _useWhiteStatusBar = [[dict objectForKey:MZAppThemeUseWhiteStatusBarKey] boolValue];
        _navBarToolbarTextTint = [UIColor colorWithString:[dict objectForKey:MZAppThemeNavBarToolBarTextTintKey]];
        _contrastingTextColor = [UIColor colorWithString:[dict objectForKey:MZAppThemeContrastingTextColor]];
    }
    return self;
}

- (NSDictionary *)nsUserDefaultsCompatibleDictFromTheme
{
    NSString *mainGuiColorString = [_mainGuiTint stringFromColor];
    NSString *navbarToolbarTextTint = [_navBarToolbarTextTint stringFromColor];
    NSString *contrastingTextColor = [_contrastingTextColor stringFromColor];
    return @{ MZAppThemeNameKey                     : _themeName,
              MZAppThemeMainGuiColorKey             : mainGuiColorString,
              MZAppThemeUseWhiteStatusBarKey        : [NSNumber numberWithBool:_useWhiteStatusBar],
              MZAppThemeNavBarToolBarTextTintKey    : navbarToolbarTextTint,
              MZAppThemeContrastingTextColor        : contrastingTextColor};
}

- (BOOL)equalToAppTheme:(MZAppTheme *)anotherTheme
{
    if(anotherTheme == self) {
        return YES;
    }
    if(![anotherTheme isMemberOfClass:[MZAppTheme class]]) {
        return NO;
    }
    
    NSString *anotherThemeMainGuiColorString = [anotherTheme.mainGuiTint stringFromColor];
    NSString *myThemeMainGuiColorString = [_mainGuiTint stringFromColor];
    
    NSString *anotherThemeNavbarToolbarString = [anotherTheme.navBarToolbarTextTint stringFromColor];
    NSString *myThemeNavbarToolbarString = [_navBarToolbarTextTint stringFromColor];
    
    NSString *anotherThemeContrastColorString = [anotherTheme.contrastingTextColor stringFromColor];
    NSString *myThemeContrastColorString = [_contrastingTextColor stringFromColor];
    
    BOOL otherThemeMainGuiTintIsDark = anotherTheme.useWhiteStatusBar;
    BOOL myThemeMainGuiTintIsDark = _useWhiteStatusBar;
    
    return [anotherTheme.themeName isEqualToString:_themeName]
        && otherThemeMainGuiTintIsDark == myThemeMainGuiTintIsDark
        && [anotherThemeMainGuiColorString isEqualToString:myThemeMainGuiColorString]
        && [anotherThemeNavbarToolbarString isEqualToString:myThemeNavbarToolbarString]
        && [anotherThemeContrastColorString isEqualToString:myThemeContrastColorString];
}


+ (MZAppTheme *)defaultAppThemeBeforeUserPickedTheme
{
    NSArray *allThemes = [MZAppTheme allAppThemes];
    for(MZAppTheme *theme in allThemes) {
        if([theme.themeName isEqualToString:MZDefaultAppThemeSunriseOrange]) {
            return theme;
        }
    }
    return nil;
}
+ (UIColor *)expandingCellGestureInitialColor
{
    return [UIColor lightGrayColor];
}
+ (UIColor *)expandingCellGestureQueueItemColor
{
    return Rgb2UIColor(114, 218, 58, 1);
}
+ (UIColor *)expandingCellGestureDeleteItemColor
{
    return Rgb2UIColor(255, 39, 39, 1);
}
+ (UIColor *)nowPlayingItemColor
{
    return [AppEnvironmentConstants appTheme].mainGuiTint;
}
+ (NSArray *)allAppThemes
{
    return  @[
              //default theme MUST be first, stupid implementation detail of the settings theme VC
              [[MZAppTheme alloc] initWithThemeName:MZDefaultAppThemeSunriseOrange
                                        mainGuiTint:Rgb2UIColor(255, 128, 8, 1)
                                  useWhiteStatusBar:YES
                              navBarToolbarTextTint:[UIColor whiteColor]
                               contrastingTextColor:Rgb2UIColor(255, 128, 8, 1)],
              
              //Bright red, with a hint of orange
              [[MZAppTheme alloc] initWithThemeName:@"Passion Red"
                                        mainGuiTint:Rgb2UIColor(228, 58, 21, 1)
                                  useWhiteStatusBar:YES
                              navBarToolbarTextTint:[UIColor whiteColor]
                               contrastingTextColor:Rgb2UIColor(228, 58, 21, 1)],
              
              [[MZAppTheme alloc] initWithThemeName:@"Cinnabar Red"
                                        mainGuiTint:Rgb2UIColor(231, 76, 60, 1)
                                  useWhiteStatusBar:YES
                              navBarToolbarTextTint:[UIColor whiteColor]
                               contrastingTextColor:Rgb2UIColor(231, 76, 60, 1)],
              
              [[MZAppTheme alloc] initWithThemeName:@"Lime Green"
                                        mainGuiTint:Rgb2UIColor(106, 145, 19, 1)
                                  useWhiteStatusBar:YES
                              navBarToolbarTextTint:[UIColor whiteColor]
                               contrastingTextColor:Rgb2UIColor(106, 145, 19, 1)],
              
              [[MZAppTheme alloc] initWithThemeName:@"Forest Green"
                                        mainGuiTint:Rgb2UIColor(44, 119, 68, 1)
                                  useWhiteStatusBar:YES
                              navBarToolbarTextTint:[UIColor whiteColor]
                               contrastingTextColor:Rgb2UIColor(44, 119, 68, 1)],
              
              [[MZAppTheme alloc] initWithThemeName:@"Deep Sky Blue"
                                        mainGuiTint:Rgb2UIColor(69, 127, 202, 1)
                                  useWhiteStatusBar:YES
                              navBarToolbarTextTint:[UIColor whiteColor]
                               contrastingTextColor:Rgb2UIColor(69, 127, 202, 1)],

              [[MZAppTheme alloc] initWithThemeName:@"Sapphire Blue"
                                        mainGuiTint:Rgb2UIColor(42, 82, 152, 1)
                                  useWhiteStatusBar:YES
                              navBarToolbarTextTint:[UIColor whiteColor]
                               contrastingTextColor:Rgb2UIColor(42, 82, 152, 1)],
              //Bluish-grey color
              [[MZAppTheme alloc] initWithThemeName:@"Dark Skies"
                                        mainGuiTint:Rgb2UIColor(75, 121, 161, 1)
                                  useWhiteStatusBar:YES
                              navBarToolbarTextTint:[UIColor whiteColor]
                               contrastingTextColor:Rgb2UIColor(75, 121, 161, 1)],
              
              [[MZAppTheme alloc] initWithThemeName:@"Orchid Purple"
                                        mainGuiTint:Rgb2UIColor(123, 67, 151, 1)
                                  useWhiteStatusBar:YES
                              navBarToolbarTextTint:[UIColor whiteColor]
                               contrastingTextColor:Rgb2UIColor(123, 67, 151, 1)],
              
              [[MZAppTheme alloc] initWithThemeName:@"Bumblebee Yellow"
                                        mainGuiTint:Rgb2UIColor(240, 203, 53, 1)
                                  useWhiteStatusBar:NO
                              navBarToolbarTextTint:[UIColor blackColor]
                               contrastingTextColor:[UIColor blackColor]],
              
              [[MZAppTheme alloc] initWithThemeName:@"Hot Pink"
                                        mainGuiTint:Rgb2UIColor(241, 95, 121, 1)
                                  useWhiteStatusBar:YES
                              navBarToolbarTextTint:Rgb2UIColor(38, 64, 99, 1)
                               contrastingTextColor:Rgb2UIColor(38, 64, 99, 1)],
              ];
}

+ (NSString *)nsUserDefaultsKeyAppThemeDict
{
    return @"NSUSERDEFAULTS - MZAppTheme key";
}

@end
