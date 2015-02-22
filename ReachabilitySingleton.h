//
//  ReachabilitySingleton.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/21/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Reachability.h>

@interface ReachabilitySingleton : NSObject

+ (instancetype)sharedInstance;
- (BOOL)isConnectedToWifi;
- (BOOL)isConnectedToCellular;
- (BOOL)isConnectedToInternet;
- (BOOL)isConnectionCompletelyGone;

@end
