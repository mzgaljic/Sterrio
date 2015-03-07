//
//  PlaybackContext.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;

@interface PlaybackContext : NSObject
@property (nonatomic, strong) NSFetchRequest *request;

- (instancetype)initWithFetchRequest:(NSFetchRequest *)aRequest;
- (BOOL)isEqualToContext:(PlaybackContext *)someContext;

@end
