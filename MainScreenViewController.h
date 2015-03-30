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
#import "BAPulseButton.h"  //category on uibutton that adds a pulse effect. imported lib...
#import "SongPlayerCoordinator.h"

@interface MainScreenViewController : UIViewController <UITabBarDelegate>

- (instancetype)initWithNavControllers:(NSArray *)navControllers
          correspondingViewControllers:(NSArray *)viewControllers
            tabBarUnselectedImageNames:(NSArray*)unSelectNames
              tabBarselectedImageNames:(NSArray*)selectNames;

@end
