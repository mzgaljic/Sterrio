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

NSString * const MZDefaultAppThemeSunriseOrange = @"Sunrise";


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
+ (NSUInteger)defaultThemeIndex
{
    return 2;
}

static NSArray *allAppThemes;
+ (NSArray *)allAppThemes
{
    if(allAppThemes != nil) {
        return allAppThemes;
    }
    
    allAppThemes = @[
                     [[MZAppTheme alloc] initWithThemeName:@"Cinnabar"
                                               mainGuiTint:Rgb2UIColor(231, 76, 60, 1)
                                         useWhiteStatusBar:YES
                                     navBarToolbarTextTint:[UIColor whiteColor]
                                      contrastingTextColor:Rgb2UIColor(231, 76, 60, 1)],
                     
                     //Bright red, with a hint of orange
                     [[MZAppTheme alloc] initWithThemeName:@"Rose"
                                               mainGuiTint:Rgb2UIColor(228, 58, 21, 1)
                                         useWhiteStatusBar:YES
                                     navBarToolbarTextTint:[UIColor whiteColor]
                                      contrastingTextColor:Rgb2UIColor(228, 58, 21, 1)],
                     
                     [[MZAppTheme alloc] initWithThemeName:MZDefaultAppThemeSunriseOrange
                                               mainGuiTint:Rgb2UIColor(255, 128, 8, 1)
                                         useWhiteStatusBar:YES
                                     navBarToolbarTextTint:[UIColor whiteColor]
                                      contrastingTextColor:Rgb2UIColor(255, 128, 8, 1)],
                     
                     [[MZAppTheme alloc] initWithThemeName:@"Bumblebee"
                                               mainGuiTint:Rgb2UIColor(240, 203, 53, 1)
                                         useWhiteStatusBar:NO
                                     navBarToolbarTextTint:[UIColor blackColor]
                                      contrastingTextColor:[UIColor blackColor]],
                     
                     [[MZAppTheme alloc] initWithThemeName:@"Lime"
                                               mainGuiTint:Rgb2UIColor(106, 145, 19, 1)
                                         useWhiteStatusBar:YES
                                     navBarToolbarTextTint:[UIColor whiteColor]
                                      contrastingTextColor:Rgb2UIColor(106, 145, 19, 1)],
                     
                     [[MZAppTheme alloc] initWithThemeName:@"Forest"
                                               mainGuiTint:Rgb2UIColor(44, 119, 68, 1)
                                         useWhiteStatusBar:YES
                                     navBarToolbarTextTint:[UIColor whiteColor]
                                      contrastingTextColor:Rgb2UIColor(44, 119, 68, 1)],
                     
                     [[MZAppTheme alloc] initWithThemeName:@"Deep Sky"
                                               mainGuiTint:Rgb2UIColor(69, 127, 202, 1)
                                         useWhiteStatusBar:YES
                                     navBarToolbarTextTint:[UIColor whiteColor]
                                      contrastingTextColor:Rgb2UIColor(69, 127, 202, 1)],
                     
                     [[MZAppTheme alloc] initWithThemeName:@"Sapphire"
                                               mainGuiTint:Rgb2UIColor(0, 103, 165, 1)
                                         useWhiteStatusBar:YES
                                     navBarToolbarTextTint:[UIColor whiteColor]
                                      contrastingTextColor:Rgb2UIColor(0, 103, 165, 1)],
                     
                     [[MZAppTheme alloc] initWithThemeName:@"Rich Blue"
                                               mainGuiTint:Rgb2UIColor(0, 114, 255, 1)
                                         useWhiteStatusBar:YES
                                     navBarToolbarTextTint:[UIColor whiteColor]
                                      contrastingTextColor:Rgb2UIColor(0, 114, 255, 1)],
                     
                     [[MZAppTheme alloc] initWithThemeName:@"Lilac"
                                               mainGuiTint:Rgb2UIColor(171, 101, 200, 1)
                                         useWhiteStatusBar:YES
                                     navBarToolbarTextTint:[UIColor whiteColor]
                                      contrastingTextColor:Rgb2UIColor(171, 101, 200, 1)],
                     
                     [[MZAppTheme alloc] initWithThemeName:@"Orchid"
                                               mainGuiTint:Rgb2UIColor(146, 87, 153, 1)
                                         useWhiteStatusBar:YES
                                     navBarToolbarTextTint:[UIColor whiteColor]
                                      contrastingTextColor:Rgb2UIColor(146, 87, 153, 1)],
                     
                     [[MZAppTheme alloc] initWithThemeName:@"Violet"
                                               mainGuiTint:Rgb2UIColor(123, 67, 151, 1)
                                         useWhiteStatusBar:YES
                                     navBarToolbarTextTint:[UIColor whiteColor]
                                      contrastingTextColor:Rgb2UIColor(123, 67, 151, 1)],
                     
                     [[MZAppTheme alloc] initWithThemeName:@"Bubblegum"
                                               mainGuiTint:Rgb2UIColor(216, 98, 165, 1)
                                         useWhiteStatusBar:YES
                                     navBarToolbarTextTint:[UIColor whiteColor]
                                      contrastingTextColor:Rgb2UIColor(216, 98, 165, 1)],
                     
                     [[MZAppTheme alloc] initWithThemeName:@"Hot Pink"
                                               mainGuiTint:Rgb2UIColor(241, 95, 121, 1)
                                         useWhiteStatusBar:YES
                                     navBarToolbarTextTint:[UIColor whiteColor]
                                      contrastingTextColor:Rgb2UIColor(38, 64, 99, 1)]
                     ];
    return allAppThemes;
}

+ (NSArray *)appThemesMatchingThemeNames:(NSArray *)themeNames
{
    NSArray<MZAppTheme *> *appThemes = [MZAppTheme allAppThemes];
    NSMutableArray *retVal = [NSMutableArray new];
    for(NSString *themeName in themeNames) {
        for(MZAppTheme *theme in appThemes) {
            if([theme.themeName caseInsensitiveCompare:themeName] == NSOrderedSame) {
                [retVal addObject:theme];
                break;
            }
        }
    }
    return retVal;
}

+ (NSString *)nsUserDefaultsKeyAppThemeDict
{
    return @"NSUSERDEFAULTS - MZAppTheme key";
}

@end
