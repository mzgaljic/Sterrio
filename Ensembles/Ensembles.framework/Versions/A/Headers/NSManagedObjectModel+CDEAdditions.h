//
//  NSManagedObjectModel+CDEAdditions.h
//  Ensembles
//
//  Created by Drew McCormack on 08/11/13.
//  Copyright (c) 2013 Drew McCormack. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectModel (CDEAdditions)

- (nonnull NSString *)cde_modelHash;
- (nonnull NSString *)cde_compressedModelHash;

- (nullable NSString *)cde_entityHashesPropertyList; // XML Dictionary
+ (nullable NSDictionary *)cde_entityHashesByNameFromPropertyList:(nullable NSString *)propertyList;

- (nonnull NSArray<NSEntityDescription *> *)cde_entitiesOrderedByMigrationPriority;

@end


@interface NSEntityDescription (CDEAdditions)

@property (nonatomic, readonly) NSUInteger cde_migrationBatchSize;
@property (nonatomic, readonly, nonnull) NSArray<NSPropertyDescription *> *cde_nonRedundantProperties;
@property (nonatomic, readonly, nonnull) NSArray<NSEntityDescription *> *cde_descendantEntities;
@property (nonatomic, readonly, nonnull) NSArray<NSEntityDescription *> *cde_ancestorEntities;

- (nonnull NSArray<NSRelationshipDescription *> *)cde_nonRedundantRelationshipsDestinedForEntities:(nullable NSArray<NSEntityDescription *> *)targetEntities;

@end


@interface NSRelationshipDescription (CDEAdditions)

@property (nonatomic, readonly) BOOL cde_isRedundant;

@end