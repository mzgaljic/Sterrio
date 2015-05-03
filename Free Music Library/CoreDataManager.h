#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

//courtesy of this question: http://stackoverflow.com/questions/14876988/core-data-uimanageddocument-or-appdelegate-to-setup-core-data-stack
@interface CoreDataManager : NSObject <UIAlertViewDelegate>

//Saves the Data Model onto the DB
- (void)saveContext;

//DataAccessLayer singleton instance shared across application
+ (id) sharedInstance;
// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound
// to the persistent store coordinator for the application.
+ (NSManagedObjectContext *)context;

//I use this ONLY for fetching, have NOT tested insertions concurrently, and probably best i dont.
+ (NSManagedObjectContext *)backgroundThreadContext;


- (BOOL)isMainThreadContextInitializedYet;
- (void)mergeEnsembleChangesIfAppropriate;
- (CDEPersistentStoreEnsemble *)ensembleForMainContext;

- (NSManagedObjectContext *)deleteOldStoreAndMakeNewOne;
@end