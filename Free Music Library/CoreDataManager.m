#import "CoreDataManager.h"

//static instance for singleton implementation
static CoreDataManager __strong *manager = nil;

//Private instance methods/properties
@interface CoreDataManager ()

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and 
// bound to the persistent store coordinator for the application.
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's 
// store added to it.
@property (readonly,strong,nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

// Returns the URL to the application's core data sql directory.
- (NSURL *)applicationSQLDirectory;
@end


@implementation CoreDataManager
static NSString *SQL_FILE_NAME = @"Muzic.sqlite";
static NSString *MODEL_NAME = @"Model 1.0";
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

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

+ (void)disposeInstance
{
    @synchronized(self)
    {
        manager = nil;
    }
}

+ (NSManagedObjectContext *)context
{
    return [[CoreDataManager sharedInstance] managedObjectContext];
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
            abort();
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
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the 
// application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil) 
        return __managedObjectModel;

    //NSURL *modelURL = [[NSBundle mainBundle] URLForResource:MODEL_NAME withExtension:@"momd"];
   // NSString *modelPath = [[NSBundle mainBundle] pathForResource:MODEL_NAME ofType:@"momd"];
    __managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return __managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the 
// application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil) 
        return __persistentStoreCoordinator;
    NSDictionary *persistentOptions = @{
                                        NSMigratePersistentStoresAutomaticallyOption:@YES,
                                        NSInferMappingModelAutomaticallyOption:@YES,
                        NSFileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication
                                        };
    NSURL *storeURL = [[self applicationSQLDirectory] URLByAppendingPathComponent:SQL_FILE_NAME];
    NSError *error = nil;
    
    // try to initialize persistent store coordinator with options defined below
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                    initWithManagedObjectModel:self.managedObjectModel];
    [__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
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
        return __persistentStoreCoordinator;
}

// Returns the URL to the application's Library directory (original method returned documents dir)
- (NSURL *)applicationSQLDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *coreDataPath = [libPath stringByAppendingPathComponent:@"Core Data"];
    
    //permission 975 for core data folder
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[fileManager attributesOfItemAtPath:libPath error:nil]];
    [attributes setValue:[NSNumber numberWithShort:975]
                  forKey:NSFilePosixPermissions];
    [attributes setValue:NSFileProtectionCompleteUntilFirstUserAuthentication forKey:NSFileProtectionKey];
    
    NSError * error = nil;
    [fileManager createDirectoryAtPath:coreDataPath
                              withIntermediateDirectories:YES
                                               attributes:attributes
                                                    error:&error];
    if(error == nil){
        //core data dir has been created. set all files in this dir to permission 975
        NSArray *files = [fileManager contentsOfDirectoryAtPath:coreDataPath error:&error];
        for(int i = 0; i < files.count; i++){
            attributes = [NSMutableDictionary dictionaryWithDictionary:[fileManager attributesOfItemAtPath:files[i] error:nil]];
            [attributes setValue:[NSNumber numberWithShort:975]
                          forKey:NSFilePosixPermissions];
            [attributes setValue:NSFileProtectionCompleteUntilFirstUserAuthentication forKey:NSFileProtectionKey];
        }
    }
    if (error != nil) {
        NSLog(@"error creating core data directory: %@", error);
        return nil;  //returning nil will allow the app to catch the error and inform the user.
    }
    
    return [NSURL fileURLWithPath:coreDataPath];
}

- (NSManagedObjectContext *)deleteOldStoreAndMakeNewOne
{
    //delete the old sqlite DB file
    NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *coreDataFolder = [libPath stringByAppendingPathComponent:@"Core Data"];
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:coreDataFolder
                                                              error:nil];
    if(! success)  //if we didn't delete the old store then clearly the whole operation failed.
        return nil;
    return [self managedObjectContext];
}


@end