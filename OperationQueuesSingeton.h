//
//  OperationQueuesSingeton.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/25/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OperationQueuesSingeton : NSObject

+ (instancetype)sharedInstance;
- (NSOperationQueue *)loadingSongsOpQueue;

@end
