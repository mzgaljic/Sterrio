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

// Returns the URL to the application's Library directory.
- (NSURL *)applicationLibraryDirectory;
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

+(NSManagedObjectContext *)context
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
    NSURL *storeURL = [[self applicationLibraryDirectory] URLByAppendingPathComponent:SQL_FILE_NAME];

    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                     initWithManagedObjectModel:[self managedObjectModel]];

    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption : @YES,
                              NSInferMappingModelAutomaticallyOption : @YES
                              };
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil URL:storeURL options:options error:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    

    return __persistentStoreCoordinator;
}

// Returns the URL to the application's Library directory (original method returned documents dir)
- (NSURL *)applicationLibraryDirectory
{
    //return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fullSqlPathWithNewDir = [self createDirectory:@"Core Data" atFilePath:libPath];
    return [NSURL fileURLWithPath:fullSqlPathWithNewDir];  //not checking for nil on purpose. want it to crash if this doesn't work.
}

- (NSString *)createDirectory:(NSString *)directoryName atFilePath:(NSString *)filePath
{
    NSString *filePathAndDirectory = [filePath stringByAppendingPathComponent:directoryName];
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:filePathAndDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    if (error != nil)
        return filePath;  //couldn't create directory, just return the original dir and let app crash (nothing i can do here)
    return filePathAndDirectory;
}

@end