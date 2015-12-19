//
//  LCTipsView.h
//  Ocarina 2
//
//  Created by Joshua Wu on 8/1/12.
//  Copyright (c) 2012 Stanford University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LCTipsView : UIView

// tip text label
@property (nonatomic, retain, readonly) UILabel *tipsLabel;

// overlay screen
@property (nonatomic, retain, readonly) UIButton *overlay;

// Show tips that were added to the queue
- (void)showNextTip;

// Forcibly dismiss tips
- (void)dismiss;

// Add a tip to the queue given a view and text
- (void)addTip:(NSString *)tip forView:(UIView *)view;

// Remove all tips from queue
- (void)removeAllTips;

@end
