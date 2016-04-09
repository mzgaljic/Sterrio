//
//  CDEAsynchronousTaskQueue.h
//  Ensembles
//
//  Created by Drew McCormack on 4/13/13.
//  Copyright (c) 2013 Drew McCormack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDEDefines.h"

typedef void (^CDEAsynchronousTaskCallbackBlock)(NSError * _Nullable error, BOOL stop);
typedef void (^CDEAsynchronousTaskBlock)(CDEAsynchronousTaskCallbackBlock _Nullable next);

typedef enum {
    CDETaskQueueTerminationPolicyStopOnError,
    CDETaskQueueTerminationPolicyStopOnSuccess,
    CDETaskQueueTerminationPolicyCompleteAll
} CDETaskQueueTerminationPolicy;

@interface CDEAsynchronousTaskQueue : NSOperation

@property (atomic, copy, readonly, nonnull) NSArray<CDEAsynchronousTaskBlock> *tasks;
@property (atomic, assign, readonly) NSUInteger numberOfTasks;
@property (atomic, assign, readonly) NSUInteger numberOfTasksCompleted;
@property (atomic, assign, readonly) CDETaskQueueTerminationPolicy terminationPolicy;
@property (atomic, strong, readwrite, nullable) id <NSObject> info;

- (nonnull instancetype)initWithTasks:(nonnull NSArray<CDEAsynchronousTaskBlock> *)tasks terminationPolicy:(CDETaskQueueTerminationPolicy)policy completion:(nullable CDECompletionBlock)completion; // Designated
- (nonnull instancetype)initWithTasks:(nonnull NSArray<CDEAsynchronousTaskBlock> *)tasks completion:(nullable CDECompletionBlock)completion;
- (nonnull instancetype)initWithTask:(nonnull CDEAsynchronousTaskBlock)task completion:(nullable CDECompletionBlock)completion;
- (nonnull instancetype)initWithTask:(nonnull CDEAsynchronousTaskBlock)task repeatCount:(NSUInteger)count terminationPolicy:(CDETaskQueueTerminationPolicy)policy completion:(nullable CDECompletionBlock)completion;

@end
