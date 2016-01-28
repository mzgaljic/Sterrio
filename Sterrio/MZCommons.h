//
//  MZCommons.h
//  Sterrio
//
//  Created by Mark Zgaljic on 1/27/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MZCommons : NSObject

void safeSynchronousDispatchToMainQueue(void (^block)(void));

@end
