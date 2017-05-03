//
//  StackController.h
//  Muzic
//
//  Last-in-first-out stack controller class.
//  Created by Mark Zgaljic on 8/15/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
  //found on: http://stackoverflow.com/questions/7567827/last-in-first-out-stack-with-gcd

@interface StackController : NSObject
{
    NSMutableArray *stack;
}

- (void) addBlock:(void (^)())block;
- (void) startNextBlock;
+ (void) performBlock:(void (^)())block;

@end