//
//  AppRatingTableViewCell.m
//  Sterrio
//
//  Created by Mark Zgaljic on 2/20/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "AppRatingTableViewCell.h"
#import "SSBouncyButton.h"
#import "AppEnvironmentConstants.h"

@implementation AppRatingTableViewCell

- (void)layoutSubviews
{
    [super layoutSubviews];
   
    UIView *view = self.contentView;
    view.backgroundColor = [UIColor defaultWindowTintColor];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    int viewWidth = view.frame.size.width;
    int viewHeight = view.frame.size.height;
    int xMid = view.frame.size.width/2;
    int yMid = view.frame.size.height/2;
    int padding = 8;
    
    int labelHeight = yMid - padding - padding;
    UILabel *enjoyingAppLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding,
                                                                          padding + labelHeight,
                                                                          view.frame.size.width,
                                                                          labelHeight)];
    enjoyingAppLabel.text = [NSString stringWithFormat:@"Enjoying %@?", MZAppName];
    enjoyingAppLabel.textColor = [UIColor defaultAppColorScheme];
    enjoyingAppLabel.textAlignment = NSTextAlignmentCenter;
    
    int buttonHeight = yMid - padding - padding;
    int buttonWidth = xMid - padding - padding;
    SSBouncyButton *notReally;
    notReally = [[SSBouncyButton alloc] initWithFrame:CGRectMake(padding,
                                                                 viewHeight - padding,
                                                                 buttonWidth,
                                                                 buttonHeight)];
    [notReally setTitle:@"Not really" forState:UIControlStateNormal];
    [notReally setTitleColor:[UIColor defaultAppColorScheme] forState:UIControlStateNormal];
    [notReally setBackgroundColor:[UIColor defaultWindowTintColor]];
    notReally.titleLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                size:notReally.titleLabel.font.pointSize];
    
    SSBouncyButton *yes;
    yes = [[SSBouncyButton alloc] initWithFrame:CGRectMake(viewWidth - buttonWidth - padding,
                                                           viewHeight - padding,
                                                           buttonWidth,
                                                           buttonHeight)];
    [yes setTitle:@"Yes!" forState:UIControlStateNormal];
    [yes setTitleColor:[UIColor defaultAppColorScheme] forState:UIControlStateNormal];
    [yes setBackgroundColor:[UIColor defaultWindowTintColor]];
    yes.titleLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                          size:notReally.titleLabel.font.pointSize];
    
    [view addSubview:enjoyingAppLabel];
    [view addSubview:notReally];
    [view addSubview:yes];
}

@end
