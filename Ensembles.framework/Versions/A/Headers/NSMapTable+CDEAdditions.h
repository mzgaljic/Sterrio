//
//  NSMapTable+CDEAdditions.h
//  Test App iOS
//
//  Created by Drew McCormack on 5/26/13.
//  Copyright (c) 2013 The Mental Faculty B.V. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMapTable (CDEAdditions)

@property (readonly, nonnull) NSArray *cde_allValues;
@property (readonly, nonnull) NSArray *cde_allKeys;

+ (nonnull instancetype)cde_weakToStrongObjectsMapTable;
+ (nonnull instancetype)cde_strongToStrongObjectsMapTable;

- (void)cde_addEntriesFromMapTable:(nullable NSMapTable *)otherTable;

@end
