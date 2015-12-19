//
//  LCTipsView.m
//  Ocarina 2
//
//  Created by Joshua Wu on 8/1/12.
//  Copyright (c) 2012 Stanford University. All rights reserved.
//

#import "LCTipsView.h"
#import <QuartzCore/QuartzCore.h>

float const ANI_TIME = 0.3f;

@interface LCTipsView()

@property (nonatomic, retain) UILabel *tipsLabel;
@property (nonatomic, retain) UIView *tipsView;
@property (nonatomic, retain) UIButton *overlay;
@property (nonatomic, retain) NSMutableArray *tips;
@property (nonatomic, retain) UIButton *tipsLabelContainer;
@property (nonatomic, retain) UIView *tipsSuperView;

- (void)setupNextTip;
- (void)cleanupTip;

@end

@implementation LCTipsView
@synthesize tipsLabel;
@synthesize tipsView;
@synthesize tips;
@synthesize tipsLabelContainer;
@synthesize tipsSuperView;
@synthesize overlay;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.alpha = 0;
        self.hidden = YES;
        
        // Setup button
        self.overlay = [UIButton buttonWithType:UIButtonTypeCustom];
        overlay.frame = self.frame;
        overlay.backgroundColor = [UIColor blackColor];
        overlay.alpha = 0.7;
        [overlay addTarget:self action:@selector(showNextTip) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:overlay];
        
        // Setup tips Button
        self.tipsLabelContainer = [UIButton buttonWithType:UIButtonTypeCustom];
        [tipsLabelContainer addTarget:self action:@selector(showNextTip) forControlEvents:UIControlEventTouchUpInside];
        tipsLabelContainer.frame = CGRectMake(0, 0, 150, 80);
        tipsLabelContainer.layer.cornerRadius = 4;
        tipsLabelContainer.backgroundColor = [UIColor blackColor];
        tipsLabelContainer.layer.borderColor = [UIColor colorWithRed:(102.0/255.0) green:(204.0/255) blue:(255.0/255) alpha:1.0].CGColor;
        tipsLabelContainer.layer.borderWidth = 1;
        tipsLabelContainer.alpha = 0;
        [self addSubview:tipsLabelContainer];
        
        // Setup tips label
        self.tipsLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 80)] autorelease];
        tipsLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
        tipsLabel.textColor = [UIColor colorWithRed:(102.0/255.0) green:(204.0/255) blue:(255.0/255) alpha:1.0];
        tipsLabel.backgroundColor = [UIColor clearColor];
        tipsLabel.numberOfLines = 0;
        tipsLabel.minimumFontSize = 8;
        tipsLabel.lineBreakMode = UILineBreakModeWordWrap;
        tipsLabel.userInteractionEnabled = NO;
        [tipsLabelContainer addSubview:tipsLabel];
        
        // Setup tips array
        self.tips = [NSMutableArray array];
    }
    
    return self;
}

- (void)dealloc {
    [tipsLabel release];
    [tipsLabelContainer release];
    [tipsView release];
    [tips release];
    [tipsSuperView release];
    [overlay release];
    
    [super dealloc];
}

#pragma mark - Private methods

- (void)setupNextTip {
    NSDictionary *nextTip = [self.tips objectAtIndex:0];

    self.tipsSuperView = [nextTip objectForKey:@"superview"];
    self.tipsView = [nextTip objectForKey:@"view"];
    tipsView.frame = CGRectMake(self.tipsView.frame.origin.x + self.tipsSuperView.frame.origin.x,
                                     self.tipsView.frame.origin.y + self.tipsSuperView.frame.origin.y,
                                     self.tipsView.frame.size.width, self.tipsView.frame.size.height);
    tipsView.alpha = 0;
    tipsView.userInteractionEnabled = NO;
    [self addSubview:tipsView];
    
    
    tipsLabel.text = [nextTip objectForKey:@"tip"];
    int tipFixWidth = 150;
    tipsLabel.frame = CGRectMake(5, 5, tipFixWidth, 0);
    [tipsLabel sizeToFit];
    
    float xOffset = ((tipFixWidth > tipsView.frame.size.width) ? (tipsView.frame.origin.x - (tipFixWidth - tipsView.frame.size.width)) : tipsView.frame.origin.x);
    float yOffset = ((self.frame.size.height <= CGRectGetMaxY(tipsView.frame) + tipsLabel.frame.size.height + 5) ? (tipsView.frame.origin.y - tipsLabel.frame.size.height - 15) : CGRectGetMaxY(self.tipsView.frame) + 5);
    tipsLabelContainer.frame = CGRectMake(xOffset, yOffset, tipsLabel.frame.size.width + 10, tipsLabel.frame.size.height + 10);
    
    [self.tips removeObjectAtIndex:0];
}

- (void)cleanupTip {
    tipsView.frame = CGRectMake(tipsView.frame.origin.x - tipsSuperView.frame.origin.x,
                                tipsView.frame.origin.y - tipsSuperView.frame.origin.y,
                                tipsView.frame.size.width, tipsView.frame.size.height);
    [tipsSuperView addSubview:tipsView];
    tipsView.userInteractionEnabled = YES;
    tipsView.alpha = 1;
    
    // Release views
    self.tipsView = nil;
    self.tipsSuperView = nil;
}

#pragma mark - Public methods

- (void)addTip:(NSString *)tip forView:(UIView *)view {
    NSDictionary *tipData = [NSDictionary dictionaryWithObjectsAndKeys:
                             view, @"view",
                             view.superview, @"superview",
                             tip, @"tip",
                             nil];
    
    [tips addObject:tipData];
}

- (void)showNextTip {    
    // Fade out previous tip
    [UIView animateWithDuration:ANI_TIME animations:^{
        tipsView.alpha = 0;
        tipsLabelContainer.alpha = 0;
    } completion:^(BOOL finished) {
        [self cleanupTip];
        
        // Cleanup may add the subview on top of the tips view
        [self.superview bringSubviewToFront:self];
        
        if ([tips count] == 0) {
            [self dismiss];
            return;
        }
        
        // Setup next tip
        [self setupNextTip];
        
        // Fade in next tip
        self.hidden = NO;
        
        [UIView animateWithDuration:ANI_TIME animations:^{
            self.alpha = 1;
            tipsView.alpha = 1;
            tipsLabelContainer.alpha = 1;
        }];
    }];
}

- (void)dismiss {
    [UIView animateWithDuration:ANI_TIME animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        self.hidden = YES;
        [self cleanupTip];
    }];
}

- (void)removeAllTips {
    [self cleanupTip];
    self.tips = [NSMutableArray array];
}
@end
