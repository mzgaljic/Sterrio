//
//  DiscogsSearchService.h
//  Sterrio
//
//  Created by Mark Zgaljic on 5/15/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMWebRequest.h"
#import "DiscogsSearchDelegate.h"
@interface DiscogsSearchService : NSObject

+ (instancetype)sharedInstance;

//instancetype returned as convenience for chaining the call on 1 line.
- (instancetype)queryWithTitle:(NSString *)title callbackDelegate:(id<DiscogsSearchDelegate>)delegate;
- (void)cancelAllPendingRequests;

@end
