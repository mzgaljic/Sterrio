#import "CoreDataManager.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "EnsembleDelegate.h"
#import "AppEnvironmentConstants.h"

//static instance for singleton implementation
static CoreDataManager __strong *manager = nil;

//Private instance methods/properties
@interface CoreDataManager ()

//Contains a strong reference to the delegate singleton.
@property (nonatomic, strong) EnsembleDelegate *ensembleDelegate;

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and 
// bound to the persistent store coordinator for the application.
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext *backgroundManagedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext *stackControllerManagedObjectContext;

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;

// Returns the URL to the application's core data sql directory.
+ (NSURL *)applicationSQLDirectory;
@end


@implementation CoreDataManager
static NSString *SQL_FILE_NAME = @"Sterrio.sqlite";
static NSString *MODEL_NAME = @"Model";
static NSPersistentStoreCoordinator *persistentStoreCoordinator = nil;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize backgroundManagedObjectContext = __backgroundManagedObjectContext;
@synthesize stackControllerManagedObjectContext = __stackControllerManagedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;

//------Ensemble Vars------
static CDEICloudFileSystem *iCloudFileSystem;
static CDEPersistentStoreEnsemble *ensemble;
NSString * const ICLOUD_CONTAINER_ID = @"iCloud.com.mzgaljic.Sterrio";
NSString * const MAIN_STORE_ENSEMBLE_ID = @"Main-Store";
//---End of Ensemble Vars---

//DataAccessLayer singleton instance shared across application
+ (id)sharedInstance
{
    @synchronized(self) 
    {
        if (manager == nil)
            manager = [[self alloc] init];
    }
    return manager;
}

/*
+ (void)disposeInstance
{
    @synchronized(self)
    {
        manager = nil;
    }
}
 */

+ (NSManagedObjectContext *)context
{
    CoreDataManager *singleton = [CoreDataManager sharedInstance];
    BOOL coreDataStackIsBeingInitialized = (singleton.isMainThreadContextInitializedYet == NO);
    
    NSManagedObjectContext *context = [singleton managedObjectContext];
    
    if(coreDataStackIsBeingInitialized){
        // Setup Ensemble
        
        iCloudFileSystem = [[CDEICloudFileSystem alloc]
                           initWithUbiquityContainerIdentifier:ICLOUD_CONTAINER_ID];
        
        NSURL *storeURL = [[CoreDataManager applicationSQLDirectory] URLByAppendingPathComponent:SQL_FILE_NAME];
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:MODEL_NAME withExtension:@"momd"];

        ensemble = [[CDEPersistentStoreEnsemble alloc] initWithEnsembleIdentifier:MAIN_STORE_ENSEMBLE_ID
                                                               persistentStoreURL:storeURL
                                                            managedObjectModelURL:modelURL
                                                                  cloudFileSystem:iCloudFileSystem];
        singleton.ensembleDelegate = [EnsembleDelegate sharedInstance];
        ensemble.delegate = singleton.ensembleDelegate;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            [CoreDataManager performRelevantActionWithCoreDataInit];
        }];
    }
    
    return context;
}

+ (void)performRelevantActionWithCoreDataInit
{
    [ensemble processPendingChangesWithCompletion:nil];
    
    if (! ensemble.isLeeched && [AppEnvironmentConstants icloudSyncEnabled])
    {
        __block CDEPersistentStoreEnsemble *blockEnsemble = ensemble;
        [ensemble leechPersistentStoreWithCompletion:^(NSError *error)
         {
             if (error){
                 NSLog(@"Could not leech to ensemble: %@", error);
             }
             else
             {
                 NSLog(@"Ensemble leeched.");
                 [blockEnsemble mergeWithCompletion:^(NSError *error)
                  {
                      if(error){
                          NSLog(@"Merge failed");
                      } else{
                          NSLog(@"Merged.");
                          [AppEnvironmentConstants setLastSuccessfulSyncDate:[[NSDate alloc] init]];
                      }
                  }];
             }
         }];
    }
    else if(ensemble.isLeeched && [AppEnvironmentConstants icloudSyncEnabled]){
        [ensemble mergeWithCompletion:^(NSError *error) {
            if(error){
                NSLog(@"Merging failed.");
            } else{
                NSLog(@"Merged successfully.");
                [AppEnvironmentConstants setLastSuccessfulSyncDate:[[NSDate alloc] init]];
            }
        }];
    }
}

+ (NSManagedObjectContext *)backgroundThreadContext
{
    return [[CoreDataManager sharedInstance] backgroundThreadManagedObjectContext];
}

+ (NSManagedObjectContext *)stackControllerThreadContext
{
    return [[CoreDataManager sharedInstance] stackControllerThreadManagedObjectContext];
}

- (BOOL)isMainThreadContextInitializedYet
{
    return (__managedObjectContext == nil) ? NO : YES;
}

- (void)mergeEnsembleChangesIfAppropriate
{
    if([AppEnvironmentConstants icloudSyncEnabled])
    {
        if(ensemble.isLeeched)
        {
            [ensemble mergeWithCompletion:^(NSError *error)
             {
                 if(error){
                     NSLog(@"Merge failed");
                 } else{
                     NSLog(@"Merged successfully.");
                     [AppEnvironmentConstants setLastSuccessfulSyncDate:[[NSDate alloc] init]];
                 }
             }];
        }
        else
        {
            __block CDEPersistentStoreEnsemble *blockEnsemble = ensemble;
            [ensemble leechPersistentStoreWithCompletion:^(NSError *error)
             {
                 if (error){
                     NSLog(@"Could not leech to ensemble: %@", error);
                 }
                 else
                 {
                     [blockEnsemble mergeWithCompletion:^(NSError *error)
                      {
                          if(error){
                              NSLog(@"Ensemble failed to merge.");
                          } else{
                              NSLog(@"Ensemble merged.");
                              [AppEnvironmentConstants setLastSuccessfulSyncDate:[[NSDate alloc] init]];
                          }
                      }];
                 }
             }];
        }
    }
}

- (CDEPersistentStoreEnsemble *)ensembleForMainContext
{
    return ensemble;
}

//Saves the Data Model onto the DB
- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) 
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) 
        {
            //Need to come up with a better error management here.
            
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            CLS_LOG(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } else{
            [ensemble processPendingChangesWithCompletion:nil];
            
            //save succeeded. now lets go the extra mile and try to merge here.
            [ensemble mergeWithCompletion:^(NSError *error) {
                if(error){
                    NSLog(@"Saved, but failed to merge.");
                } else{
                    NSLog(@"Saved and Merged.");
                    [AppEnvironmentConstants setLastSuccessfulSyncDate:[[NSDate alloc] init]];
                }
            }];
        }
    }
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and 
// bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
        return __managedObjectContext;

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) 
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
        [__managedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
        
        NSUndoManager *undoManager = [[NSUndoManager alloc] init];
        [__managedObjectContext setUndoManager:undoManager];
    }
    return __managedObjectContext;
}

- (NSManagedObjectContext *)stackControllerThreadManagedObjectContext
{
    if (__stackControllerManagedObjectContext != nil)
        return __stackControllerManagedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __stackControllerManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        //should NOT be setting the persistentStoreCoordinator more than once.
        //[__stackControllerManagedObjectContext setPersistentStoreCoordinator:coordinator];
        
        NSUndoManager *undoManager = [[NSUndoManager alloc] init];
        [__stackControllerManagedObjectContext setUndoManager:undoManager];
    }
    return __stackControllerManagedObjectContext;
}

- (NSManagedObjectContext *)backgroundThreadManagedObjectContext
{
    if (__backgroundManagedObjectContext != nil)
        return __backgroundManagedObjectContext;
    
    __backgroundManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    NSUndoManager *undoManager = [[NSUndoManager alloc] init];
    [__backgroundManagedObjectContext setUndoManager:undoManager];
    __backgroundManagedObjectContext.parentContext = [self managedObjectContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backgroundThreadChildContextSaved)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];
    
    return __backgroundManagedObjectContext;
}

//useful for when background context (album art updater) saves changes.
- (void)backgroundThreadChildContextSaved
{
    if([self managedObjectContext].updatedObjects.count > 0) {
        __weak CoreDataManager *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf saveContext];
        });
    }
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the 
// application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil) 
        return __managedObjectModel;

    //use this is problems occur with url.
    //__managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:MODEL_NAME withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return __managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the 
// application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil)
        return persistentStoreCoordinator;
    NSDictionary *persistentOptions = @{
                                        NSMigratePersistentStoresAutomaticallyOption:@YES,
                                        NSInferMappingModelAutomaticallyOption:@YES,
                        NSFileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication
                                        };
    NSURL *storeURL = [[CoreDataManager applicationSQLDirectory] URLByAppendingPathComponent:SQL_FILE_NAME];
    NSError *error = nil;
    
    // try to initialize persistent store coordinator with options defined below
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                    initWithManagedObjectModel:self.managedObjectModel];
    [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                               configuration:nil URL:storeURL options:persistentOptions error:&error];
    if(error)
    {
        NSLog(@"[ERROR] Problem initializing persistent store coordinator:\n %@, %@", error,
                                                            [error localizedDescription]);
        
        //usually happens when the underlying model is different than the one our program is using.
        //I test for this in StartupViewController.h
        return nil;
    }
    else
        return persistentStoreCoordinator;
}

// Returns the URL to the application's Library directory (original method returned documents dir)
+ (NSURL *)applicationSQLDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *coreDataPath = [libPath stringByAppendingPathComponent:@"Core Data"];
    
    NSError * error = nil;
    [fileManager createDirectoryAtPath:coreDataPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    if (error != nil) {
        NSLog(@"error creating core data directory: %@", error);
        return nil;  //returning nil will allow the app to catch the error and inform the user.
    }
    
    return [NSURL fileURLWithPath:coreDataPath];
}

- (NSManagedObjectContext *)deleteOldStoreAndMakeNewOne
{
    BOOL icloudOriginallyActive = [AppEnvironmentConstants icloudSyncEnabled];
    [AppEnvironmentConstants set_iCloudSyncEnabled:NO tryToBlindlySet:NO];
    //delete the old sqlite DB file
    NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *coreDataFolder = [libPath stringByAppendingPathComponent:@"Core Data"];
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:coreDataFolder
                                                              error:nil];
    if(! success)  //if we didn't delete the old store then clearly the whole operation failed.
        return nil;
    
    NSManagedObjectContext *newContext = [self managedObjectContext];
    [AppEnvironmentConstants set_iCloudSyncEnabled:icloudOriginallyActive tryToBlindlySet:NO];
    return newContext;
}


@end