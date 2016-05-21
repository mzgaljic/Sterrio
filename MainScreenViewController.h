//
//  MainScreenViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyViewController.h"
#import "AppEnvironmentConstants.h"
#import "UIColor+LighterAndDarker.h"
#import "UIButton+ExpandedHitArea.h"
#import "UIImage+colorImages.h"
#import "MainScreenViewControllerDelegate.h"
#import "SSBouncyButton.h"
#import "SongPlayerCoordinator.h"
#import "CMPopTipView.h"
@import GoogleMobileAds;

@interface MainScreenViewController : UIViewController <UITabBarDelegate,
                                                        GADBannerViewDelegate,
                                                        CMPopTipViewDelegate>

@property (nonatomic, assign) BOOL introOnScreen;

- (instancetype)initWithNavControllers:(NSArray *)navControllers
          correspondingViewControllers:(NSArray *)viewControllers
            tabBarUnselectedImageNames:(NSArray*)unSelectNames
              tabBarselectedImageNames:(NSArray*)selectNames;

@end
