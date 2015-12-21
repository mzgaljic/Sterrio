//
//  IntroVideoView.h
//  Sterrio
//
//  Created by Mark Zgaljic on 12/20/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IntroVideoView : UIView

- (instancetype)initWithFrame:(CGRect)frame
                        title:(NSString *)title
                  description:(NSString *)desc
                     videoUrl:(NSURL *)url;
- (void)startVideoLooping;
- (void)stopPlaybackAndResetToBeginning;

@end
