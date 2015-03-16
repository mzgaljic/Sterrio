//
//  PlaybackContext.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"
@import CoreData;

@interface PlaybackContext : NSObject
@property (nonatomic, strong) NSFetchRequest *request;
@property (nonatomic, strong) NSString *queueName;

- (instancetype)initWithFetchRequest:(NSFetchRequest *)aRequest prettyQueueName:(NSString *)name;

- (BOOL)isEqualToContext:(PlaybackContext *)someContext;

@end
