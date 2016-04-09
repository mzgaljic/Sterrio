//
//  CDEFoundationAdditions.h
//  Test App iOS
//
//  Created by Drew McCormack on 4/19/13.
//  Copyright (c) 2013 The Mental Faculty B.V. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (CDEFoundationAdditions)

- (void)cde_enumerateObjectsDrainingEveryIterations:(NSUInteger)iterationsBetweenDrains usingBlock:(nonnull void (^)(id _Nonnull object, NSUInteger index, BOOL *_Nonnull stop))block;
- (void)cde_enumerateObjectsInBatchesWithBatchSize:(NSUInteger)batchSize usingBlock:(nonnull void (^)(NSArray * _Nonnull batch, NSUInteger batchesRemaining, BOOL * _Nonnull stop))block;

- (nonnull NSArray *)cde_arrayByTransformingObjectsWithBlock:(id _Nonnull (^ _Nullable)(id _Nonnull))block;

@end


@interface NSData (CDEFoundationAdditions)

- (nonnull NSString *)cde_base64String;

@end
