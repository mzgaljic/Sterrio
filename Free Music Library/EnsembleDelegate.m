//
//  EnsembleDelegate.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/2/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "EnsembleDelegate.h"
#import "CoreDataManager.h"
#import "AlbumAlbumArt.h"
#import "SongAlbumArt.h"

@implementation EnsembleDelegate

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    if(self = [super init]){
        NSString *newFilesToMergeNotif = CDEICloudFileSystemDidDownloadFilesNotification;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(ensemblesHasDownloadedFilesToMerge)
                                                     name:newFilesToMergeNotif
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    //shouldnt ever be called, but whatever lol.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)ensemblesHasDownloadedFilesToMerge
{
    //we try to merge when user returns app to foreground. lets only merge these changes
    //if app is currently the active app.
    if([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
        return;
    
    CDEPersistentStoreEnsemble *ensemble = [[CoreDataManager sharedInstance] ensembleForMainContext];
    [ensemble mergeWithCompletion:^(NSError *error) {
        if(error){
            NSLog(@"Files were just downloaded, but merge failed.");
        } else{
            NSLog(@"Files just downloaded and merged.");
        }
    }];
}

//METHOD INVOKED ON BACKGROUND THREAD
- (void)persistentStoreEnsemble:(CDEPersistentStoreEnsemble *)ensemble didSaveMergeChangesWithNotification:(NSNotification *)notification
{
    NSManagedObjectContext *managedObjectContext = [CoreDataManager context];
    [managedObjectContext performBlock:^{
        [managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    }];
    
    NSManagedObjectContext *backgroundManagedObjectContext = [CoreDataManager backgroundThreadContext];
    [backgroundManagedObjectContext performBlock:^{
        [backgroundManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    }];
}

//METHOD INVOKED ON BACKGROUND THREAD
- (BOOL)persistentStoreEnsemble:(CDEPersistentStoreEnsemble*)ensemble shouldSaveMergedChangesInManagedObjectContext:(NSManagedObjectContext *)savingContext reparationManagedObjectContext:(NSManagedObjectContext *)reparationContext
{
    return ([AppEnvironmentConstants isABadTimeToMergeEnsemble]) ? NO : YES;
}

//METHOD INVOKED ON BACKGROUND THREAD
- (NSArray *)persistentStoreEnsemble:(CDEPersistentStoreEnsemble *)ensemble
  globalIdentifiersForManagedObjects:(NSArray *)objects
{
    NSMutableArray *arrayOfIds = [NSMutableArray array];
    [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [arrayOfIds addObject:[EnsembleDelegate globalIdentifierForObject:obj]];
    }];
    
    return arrayOfIds;
}

+ (id)globalIdentifierForObject:(id)someObject
{
    if([someObject respondsToSelector:@selector(uniqueId)]){
        return [someObject performSelector:@selector(uniqueId)];
    } else
        return [NSNull null];
}

@end
