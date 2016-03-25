//
//  MZAppTheme.m
//  Sterrio
//
//  Created by Mark Zgaljic on 3/24/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZAppTheme.h"
#import "UIColor+Strings.h"
#import "AppEnvironmentConstants.h"

@interface MZAppTheme ()
@property (nonatomic, strong, readwrite) UIColor *mainGuiTint;
@property (nonatomic, strong, readwrite) UIColor *contrastingTextOrNavBarTint;
@end

@implementation MZAppTheme
#define Rgb2UIColor(r, g, b, a)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:(a)]
NSString * const MZAppThemeMainGuiColorKey = @"Main Gui Tint";
NSString * const MZAppThemeContrastTextOrNavBarColorKey = @"Contrasting Text/Nav Color";

- (instancetype)initWithMainGuiTint:(UIColor *)mainGuiColor
         constrastingTextOrNavColor:(UIColor *)contrastingColor
{
    if(self = [super init]) {
        _mainGuiTint = mainGuiColor;
        _contrastingTextOrNavBarTint = contrastingColor;
    }
    return self;
}

- (instancetype)initWithNsUserDefaultsCompatibleDict:(NSDictionary *)dict;
{
    if(self = [super init]) {
        _mainGuiTint = [UIColor colorWithString:[dict objectForKey:MZAppThemeMainGuiColorKey]];
        _contrastingTextOrNavBarTint = [UIColor colorWithString:[dict objectForKey:MZAppThemeContrastTextOrNavBarColorKey]];
    }
    return self;
}

- (NSDictionary *)nsUserDefaultsCompatibleDictFromTheme
{
    NSString *mainGuiColorString = [self.mainGuiTint stringFromColor];
    NSString *contrastingTextOrNavColorString = [self.contrastingTextOrNavBarTint stringFromColor];
    return @{ mainGuiColorString                  : MZAppThemeMainGuiColorKey,
              contrastingTextOrNavColorString     : MZAppThemeContrastTextOrNavBarColorKey };
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
    
    NSString *anotherThemeContrastColorString = [anotherTheme.contrastingTextOrNavBarTint stringFromColor];
    NSString *myThemeContrastColorString = [_contrastingTextOrNavBarTint stringFromColor];
    
    return [anotherThemeMainGuiColorString isEqualToString:myThemeMainGuiColorString]
        && [anotherThemeContrastColorString isEqualToString:myThemeContrastColorString];
}


+ (MZAppTheme *)defaultAppThemeBeforeUserPickedTheme
{
    UIColor *mainGuiTint = Rgb2UIColor(240, 110, 50, 1);
    UIColor *contrastingTextColor = [UIColor whiteColor];
    MZAppTheme *defaultAppTheme = [[MZAppTheme alloc] initWithMainGuiTint:mainGuiTint
                                               constrastingTextOrNavColor:contrastingTextColor];
    return defaultAppTheme;
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
    /*
     return  @[
     //orange
     [AppEnvironmentConstants defaultAppThemeBeforeUserPickedTheme],
     
     //green
     [Rgb2UIColor(74, 153, 118, 1) darkerColor],
     
     //pink
     [Rgb2UIColor(233, 91, 152, 1) lighterColor],
     
     //blue
     Rgb2UIColor(57, 104, 190, 1),
     
     //purple
     Rgb2UIColor(111, 91, 164, 1),
     
     //yellow
     Rgb2UIColor(254, 200, 45, 1)
     ];
     */
    UIColor *whiteColor = [UIColor whiteColor];
    UIColor *blackColor = [UIColor blackColor];
    return  @[
              //orange
              [MZAppTheme defaultAppThemeBeforeUserPickedTheme],
              
              //From top left, going down, and then back up, in zig-zag motion, from left -> right
              //on app logo.
              [[MZAppTheme alloc] initWithMainGuiTint:Rgb2UIColor(169, 96, 143, 1) constrastingTextOrNavColor:whiteColor],
              [[MZAppTheme alloc] initWithMainGuiTint:Rgb2UIColor(101, 103, 201, 1) constrastingTextOrNavColor:whiteColor],
              [[MZAppTheme alloc] initWithMainGuiTint:Rgb2UIColor(188, 97, 143, 1) constrastingTextOrNavColor:whiteColor],
              [[MZAppTheme alloc] initWithMainGuiTint:Rgb2UIColor(225, 152, 89, 1)constrastingTextOrNavColor:whiteColor],
              [[MZAppTheme alloc] initWithMainGuiTint:Rgb2UIColor(229, 185, 78, 1)constrastingTextOrNavColor:blackColor],
              [[MZAppTheme alloc] initWithMainGuiTint:Rgb2UIColor(218, 100, 90, 1)constrastingTextOrNavColor:whiteColor],
              [[MZAppTheme alloc] initWithMainGuiTint:Rgb2UIColor(119, 103, 202, 1)constrastingTextOrNavColor:whiteColor],
              [[MZAppTheme alloc] initWithMainGuiTint:Rgb2UIColor(159, 85, 227, 1)constrastingTextOrNavColor:whiteColor],
              //default orange here, skipped since it's the first element in array.
              [[MZAppTheme alloc] initWithMainGuiTint:Rgb2UIColor(188, 81, 170, 1)constrastingTextOrNavColor:whiteColor],
              [[MZAppTheme alloc] initWithMainGuiTint:Rgb2UIColor(221, 141, 94, 1)constrastingTextOrNavColor:whiteColor],
              [[MZAppTheme alloc] initWithMainGuiTint:Rgb2UIColor(188, 97, 143, 1)constrastingTextOrNavColor:whiteColor],
              [[MZAppTheme alloc] initWithMainGuiTint:Rgb2UIColor(119, 190, 168, 1)constrastingTextOrNavColor:blackColor],
              [[MZAppTheme alloc] initWithMainGuiTint:Rgb2UIColor(109, 180, 205, 1)constrastingTextOrNavColor:blackColor],
              ];
}

+ (NSString *)nsUserDefaultsKeyAppThemeDict
{
    return @"NSUSERDEFAULTS - MZAppTheme key";
}

@end
