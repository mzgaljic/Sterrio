//
//  IntroVideoView.h
//  Sterrio
//
//  Created by Mark Zgaljic on 12/20/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MZAppTheme.h"

@interface IntroVideoView : UIView

- (instancetype)initWithFrame:(CGRect)frame
                        title:(NSString *)title
                  description:(NSString *)desc
           introVideoRecordId:(NSString *)recordId
                   mzAppTheme:(MZAppTheme *)anAppTheme;
- (void)startVideoLooping;
- (void)stopPlaybackAndResetToBeginning;

//just a helper for outside classes since the description label placement depends
//on the players size (and that is dynamic)
+ (int)descriptionYValueForViewSize:(CGSize)size;

@end
