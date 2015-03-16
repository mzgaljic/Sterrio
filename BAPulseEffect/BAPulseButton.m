//The MIT License (MIT)
//
//Copyright (c) 2014 Bryan Antigua
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

#import "BAPulseButton.h"

@implementation BAPulseButton{
    
    CAShapeLayer* pulseOutline;
    
}

-  (id)initWithFrame:(CGRect)aRect
{
    self = [super initWithFrame:aRect];
    
    if (self)
    {
        [self configure];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self configure];
    }
    return self;
}


-(void)configure{
    
    //making button round
    self.layer.cornerRadius = self.frame.size.height/2;
    
    
    //configuring click effect
    pulseOutline = [CAShapeLayer layer];
    pulseOutline.frame = self.bounds;
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:
                          CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
    [pulseOutline setPath:[path CGPath]];
    [pulseOutline setStrokeColor:[[UIColor blackColor] CGColor]];
    [pulseOutline setFillColor:[UIColor clearColor].CGColor];
    [pulseOutline setLineWidth:0.3f];
    [self.layer insertSublayer:pulseOutline below:self.layer];
    pulseOutline.opacity = 0.0f;
}

-(void)changePulseOutlineColor:(UIColor*) color{
    [pulseOutline setStrokeColor:[color CGColor]];
}

- (void)buttonPressAnimation{
    
    CABasicAnimation *popAnimation;
    popAnimation=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
    popAnimation.duration=.1;
    popAnimation.repeatCount=1;
    popAnimation.autoreverses=YES;
    popAnimation.fromValue=@1.0;
    popAnimation.toValue=@1.1;
    [self.layer addAnimation:popAnimation forKey:@"animateOpacity"];
    
    CABasicAnimation *pulseAnimation;
    pulseAnimation=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulseAnimation.duration=.4;
    pulseAnimation.repeatCount=1;
    pulseAnimation.fromValue=@1.0;
    pulseAnimation.toValue=@1.3;
    [pulseOutline addAnimation:pulseAnimation forKey:@"animateOpacity"];
    
    
    CABasicAnimation *fadeOutAnimation;
    fadeOutAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeOutAnimation.duration=.2;
    fadeOutAnimation.repeatCount=1;
    fadeOutAnimation.autoreverses = YES;
    fadeOutAnimation.fromValue=@0.0;
    fadeOutAnimation.toValue=@1.0;
    [pulseOutline addAnimation:fadeOutAnimation forKey:@"opacity"];
}
@end
