//
//  SDCAlertControllerView.m
//  SDCAlertView
//
//  Created by Scott Berrevoets on 9/21/14.
//  Copyright (c) 2014 Scotty Doesn't Code. All rights reserved.
//

#import "SDCAlertControllerView.h"

#import "PreferredFontSizeUtility.h"
#import "SDCAlertControllerTextFieldViewController.h"

#import "SDCAlertController.h"
#import "SDCAlertViewBackgroundView.h"
#import "SDCAlertControllerScrollView.h"
#import "SDCAlertControllerCollectionViewFlowLayout.h"
#import "SDCAlertCollectionViewCell.h"
#import "SDCIntrinsicallySizedView.h"

#import "UIView+SDCAutoLayout.h"
#import "UIView+Parallax.h"

static NSString *const SDCAlertControllerCellReuseIdentifier = @"SDCAlertControllerCellReuseIdentifier";

@interface SDCAlertControllerView () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>
@property (nonatomic, strong) UIVisualEffectView *visualEffectView;
@property (nonatomic, strong) SDCAlertControllerScrollView *scrollView;
@property (nonatomic, strong) UICollectionView *actionsCollectionView;
@property (nonatomic, strong) SDCAlertControllerCollectionViewFlowLayout *collectionViewLayout;
@property (nonatomic, strong) NSLayoutConstraint *maximumHeightConstraint;

//fixed bug when showing App terms using SFSafariController, dismissing it, and then dismiss the alert.
@property (nonatomic, assign) BOOL addedKeyValueObservers;
@end

@implementation SDCAlertControllerView

#pragma mark - Lifecycle

- (instancetype)initWithTitle:(NSAttributedString *)title message:(NSAttributedString *)message {
	self = [self init];
	
	if (self) {
		UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
		_visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
		[_visualEffectView setTranslatesAutoresizingMaskIntoConstraints:NO];
		
		_scrollView = [[SDCAlertControllerScrollView alloc] initWithTitle:title message:message];
		
		_collectionViewLayout = [[SDCAlertControllerCollectionViewFlowLayout alloc] init];
		[_collectionViewLayout registerClass:[SDCAlertControllerSeparatorView class] forDecorationViewOfKind:SDCAlertControllerDecorationKindHorizontalSeparator];
		[_collectionViewLayout registerClass:[SDCAlertControllerSeparatorView class] forDecorationViewOfKind:SDCAlertControllerDecorationKindVerticalSeparator];
		
		_actionsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_collectionViewLayout];
		[_actionsCollectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
		[_actionsCollectionView registerClass:[SDCAlertCollectionViewCell class] forCellWithReuseIdentifier:SDCAlertControllerCellReuseIdentifier];
		_actionsCollectionView.delaysContentTouches = NO;
		
		_actionsCollectionView.delegate = self;
		_actionsCollectionView.dataSource = self;
		_actionsCollectionView.backgroundColor = [UIColor clearColor];
				
		[self setTranslatesAutoresizingMaskIntoConstraints:NO];
	}
	
	return self;
}

- (void)dealloc {
    if(_addedKeyValueObservers) {
        [self.actions enumerateObjectsUsingBlock:^(SDCAlertAction *action, NSUInteger idx, BOOL *stop) {
            [action removeObserver:self forKeyPath:@"enabled"];
        }];
    }
}

#pragma mark - Getters & Setters

- (NSAttributedString *)title {
	return self.scrollView.title;
}

- (void)setTitle:(NSAttributedString *)title {
	self.scrollView.title = title;
}

- (NSAttributedString *)message {
	return self.scrollView.message;
}

- (void)setMessage:(NSAttributedString *)message {
	self.scrollView.message = message;
}

- (void)setActionLayout:(SDCAlertControllerActionLayout)actionLayout {
	_actionLayout = actionLayout;
	
	UICollectionViewScrollDirection direction = UICollectionViewScrollDirectionHorizontal;
	
	if (actionLayout == SDCAlertControllerActionLayoutVertical
        || (actionLayout == SDCAlertControllerActionLayoutAutomatic && self.actions.count != 2)) {
		direction = UICollectionViewScrollDirectionVertical;
	}
    
    if(actionLayout == SDCAlertControllerActionLayoutAutomatic && self.actions.count == 2) {
        //should it really be horizontal if the action count is 2? lets find out...
        
        //put together a big string with all the action titles combined.
        //Then, make fake uilabel with the proper font size and see how wide
        //it would really be. If too wide, make the collectionView vertical!
        //mush less hackish than just checking the # of actions.
        NSArray *actions = self.actions;
        SDCAlertAction *action1 = actions[0];
        SDCAlertAction *action2 = actions[1];
        
        //AWFUL hack to figure out the general frame size of the alert view. The view itself
        //is not created yet in this method so we need to simulate that.
        SDCAlertControllerTextFieldViewController *temp = [[SDCAlertControllerTextFieldViewController alloc] initWithTextFields:nil visualStyle:nil];
        
        CGRect rect = temp.view.frame;
        int labelHeight = [self collectionViewHeightGivenHypotheticalLayout:SDCAlertControllerActionLayoutHorizontal];
        
        float actionButtonWidth = rect.size.width / 2;
        
        UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(rect.origin.x,
                                                                   rect.origin.y,
                                                                   1000,
                                                                   labelHeight)];
        label1.text = action1.title;
        label1.numberOfLines = 0;
        label1.font = [self fontForAction:action1];
        [label1 sizeToFit];
        
        UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(rect.origin.x,
                                                                    rect.origin.y,
                                                                    1000,
                                                                    labelHeight)];
        label2.text = action2.title;
        label2.numberOfLines = 0;
        label2.font = [self fontForAction:action2];
        [label2 sizeToFit];
        
        int longestLabelWidth = label1.frame.size.width;
        if(label2.frame.size.width > longestLabelWidth) {
            longestLabelWidth = label2.frame.size.width;
        }
        
        if(longestLabelWidth >= (actionButtonWidth * 0.70)) {
            //the action with the longer text would appear squished! lets make it vertical after all.
            _actionLayout = SDCAlertControllerActionLayoutVertical;
            direction = UICollectionViewScrollDirectionVertical;
            return;
        }
    }
    
	self.collectionViewLayout.scrollDirection = direction;
}

//horrible hack, copy pasted from another class in this lib.
- (UIFont *)fontForAction:(SDCAlertAction *)action {
    int fontSize = [PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize];
    int minFontSize = 17;
    if(fontSize < minFontSize)
        fontSize = minFontSize;
    
    int maxFontSize = 22;
    if(fontSize > maxFontSize)
        fontSize = maxFontSize;
    
    UIFont *myFont;
    if (action.style & SDCAlertActionStyleRecommended) {
        myFont = [UIFont fontWithName:[AppEnvironmentConstants boldFontName] size:fontSize];
        return myFont;
    } else {
        myFont = [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:fontSize];
        return myFont;
    }
}


- (void)setVisualStyle:(id<SDCAlertControllerVisualStyle>)visualStyle {
	_visualStyle = visualStyle;
	self.layer.masksToBounds = YES;
	self.layer.cornerRadius = visualStyle.cornerRadius;
	
	[self sdc_addParallax:visualStyle.parallax];
}

#pragma mark - Content

- (void)showTextFieldViewController:(SDCAlertControllerTextFieldViewController *)viewController {
	self.scrollView.textFieldViewController = viewController;
}

- (void)actionViewTapped:(UITapGestureRecognizer *)sender {
	SDCAlertCollectionViewCell *cell = (SDCAlertCollectionViewCell *)sender.view;
	NSIndexPath *indexPath = [self.actionsCollectionView indexPathForCell:cell];
	SDCAlertAction *action = self.actions[indexPath.row];
	
	[self.delegate alertControllerView:self didPerformAction:action];
}

#pragma mark - User Interface

- (CGFloat)maximumHeightForScrollView {
	CGFloat maximumHeight = CGRectGetHeight(self.superview.bounds) - self.visualStyle.margins.top - self.visualStyle.margins.bottom;
	
	if (self.actions.count > 0) {
		if (self.collectionViewLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
			maximumHeight -= self.visualStyle.actionViewHeight;
		} else {
			maximumHeight -= self.visualStyle.actionViewHeight * [self.actionsCollectionView numberOfItemsInSection:0];
		}
	}
	
	return maximumHeight;
}

- (void)prepareForDisplay {
	[self observeActions];
	[self applyCurrentStyleToAlertElements];
	
	[self.visualEffectView.contentView addSubview:self.scrollView];
	[self.scrollView finalizeElements];
	
	[self.scrollView sdc_alignEdgesWithSuperview:UIRectEdgeLeft|UIRectEdgeTop|UIRectEdgeRight];
	self.maximumHeightConstraint = [self.scrollView sdc_setMaximumHeight:[self maximumHeightForScrollView]];
	
	UIView *aligningView = self.scrollView;
	if (self.contentView.subviews.count > 0) {
		aligningView = self.contentView;
		
		[self.visualEffectView.contentView addSubview:self.contentView];
		[self.contentView sdc_alignEdges:UIRectEdgeLeft|UIRectEdgeRight withView:self.scrollView];
		[self.contentView sdc_alignEdge:UIRectEdgeTop withEdge:UIRectEdgeBottom ofView:self.scrollView];
	}
	
	[self.visualEffectView.contentView addSubview:self.actionsCollectionView];
	[self.actionsCollectionView sdc_alignEdge:UIRectEdgeTop withEdge:UIRectEdgeBottom ofView:aligningView];
	[self.actionsCollectionView sdc_alignEdgesWithSuperview:UIRectEdgeLeft|UIRectEdgeBottom|UIRectEdgeRight];
	[self.actionsCollectionView sdc_pinHeight:[self collectionViewHeight]];
	
	[self addSubview:self.visualEffectView];
	[self.visualEffectView sdc_alignEdgesWithSuperview:UIRectEdgeAll];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	self.maximumHeightConstraint.constant = [self maximumHeightForScrollView];
}

- (void)applyCurrentStyleToAlertElements {
	self.scrollView.visualStyle = self.visualStyle;
	self.collectionViewLayout.visualStyle = self.visualStyle;
}

#pragma mark - KVO

- (void)observeActions {
    if(! _addedKeyValueObservers) {
        [self.actions enumerateObjectsUsingBlock:^(SDCAlertAction *action, NSUInteger idx, BOOL *stop) {
            [action addObserver:self forKeyPath:@"enabled" options:0 context:NULL];
        }];
    }
    _addedKeyValueObservers = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([object isKindOfClass:[SDCAlertAction class]]) {
		SDCAlertAction *action = object;
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.actions indexOfObject:action] inSection:0];
		
		SDCAlertCollectionViewCell *cell = (SDCAlertCollectionViewCell *)[self.actionsCollectionView cellForItemAtIndexPath:indexPath];
		cell.enabled = action.isEnabled;
	}
}

#pragma mark - UICollectionView
- (CGFloat)collectionViewHeightGivenHypotheticalLayout:(SDCAlertControllerActionLayout)layout
{
    CGFloat horizontalLayoutHeight = self.visualStyle.actionViewHeight;
    CGFloat verticalLayoutHeight = self.visualStyle.actionViewHeight * [self.actionsCollectionView numberOfItemsInSection:0];
    
    switch (layout) {
        case SDCAlertControllerActionLayoutAutomatic:		return (self.actions.count == 2) ? horizontalLayoutHeight : verticalLayoutHeight;
        case SDCAlertControllerActionLayoutHorizontal:		return horizontalLayoutHeight;
        case SDCAlertControllerActionLayoutVertical:		return verticalLayoutHeight;
    }

}

- (CGFloat)collectionViewHeight {
	CGFloat horizontalLayoutHeight = self.visualStyle.actionViewHeight;
	CGFloat verticalLayoutHeight = self.visualStyle.actionViewHeight * [self.actionsCollectionView numberOfItemsInSection:0];
	
	switch (self.actionLayout) {
		case SDCAlertControllerActionLayoutAutomatic:		return (self.actions.count == 2) ? horizontalLayoutHeight : verticalLayoutHeight;
		case SDCAlertControllerActionLayoutHorizontal:		return horizontalLayoutHeight;
		case SDCAlertControllerActionLayoutVertical:		return verticalLayoutHeight;
	}
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.actions.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	SDCAlertCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:SDCAlertControllerCellReuseIdentifier
																				 forIndexPath:indexPath];
	
	SDCAlertAction *action = self.actions[indexPath.item];
	[cell updateWithAction:action visualStyle:self.visualStyle];
	cell.gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionViewTapped:)];
	return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
				  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	if (self.collectionViewLayout.scrollDirection == UICollectionViewScrollDirectionVertical) {
		return CGSizeMake(CGRectGetWidth(self.bounds), self.visualStyle.actionViewHeight);
	} else {
		CGFloat width = MAX(CGRectGetWidth(self.bounds) / self.actions.count, self.visualStyle.minimumActionViewWidth);
		return CGSizeMake(width, self.visualStyle.actionViewHeight);
	}
}

@end
