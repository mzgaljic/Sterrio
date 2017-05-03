//
//  CDEDefines.h
//  Ensembles
//
//  Created by Drew McCormack on 4/11/13.
//  Copyright (c) 2013 Drew McCormack. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark Exceptions

extern NSString * const CDEException;
extern NSString * const CDEErrorDomain;


#pragma mark Types

typedef int64_t CDERevisionNumber;
typedef int64_t CDEGlobalCount;


#pragma mark Model User Info Keys

extern NSString * const CDEMigrationBatchSizeKey; /// Batch size to use when handling data for a given entity
extern NSString * const CDEMigrationPriorityKey;  /// Integer stipulating rank of entity in traversal. Larger is earlier.
extern NSString * const CDEIgnoredKey;            /// With a non-zero value, the entity or property is ignored.

NS_ASSUME_NONNULL_END

#pragma mark Errors

typedef NS_ENUM(NSInteger, CDEErrorCode) {
    /// An unknown error occurred.
    CDEErrorCodeUnknown                     = -1,
    
    /// The operation was cancelled.
    CDEErrorCodeCancelled                   = 101,
    
    /// Multiple errors occurred. The `errors` key of `userInfo` has them all.
    CDEErrorCodeMultipleErrors              = 102,
    
    /// A request for an invalid state transition was made. Eg Merge during leeching.
    CDEErrorCodeDisallowedStateChange       = 103,
    
    /// An unexpected internal exception was raised and caught.
    CDEErrorCodeExceptionRaised             = 104,
    
    /// An attempt to write a file failed.
    CDEErrorCodeFailedToWriteFile           = 105,
    
    /// Accessing a file with a coordinator timed out. Often because iCloud is still downloading. Retry later.
    CDEErrorCodeFileCoordinatorTimedOut     = 106,
    
    /// An attempt to access a file failed.
    CDEErrorCodeFileAccessFailed            = 107,
    
    /// The requested directory does not exist
    CDEErrorCodeDirectoryDoeNotExist        = 108,
    
    /// User changed cloud identity. This forces a deleech.
    CDEErrorCodeCloudIdentityChanged        = 202,
    
    /// Some left over, incomplete data has been found. Probably due to a crash.
    CDEErrorCodeDataCorruptionDetected      = 203,
    
    /// A model version exists in the cloud that is unknown. Merge will succeed again after update.
    CDEErrorCodeUnknownModelVersion         = 204,
    
    /// The ensemble is no longer registered in the cloud. Usually due to cloud data removal.
    CDEErrorCodeStoreUnregistered           = 205,
    
    /// A save to the persistent store occurred during leech. This is not allowed.
    CDEErrorCodeSaveOccurredDuringLeeching  = 206,
    
    /// A save to the persistent store occurred during merge. You can simply retry the merge.
    CDEErrorCodeSaveOccurredDuringMerge     = 207,
    
    /// No snapshot of existing cloud files exists. This is a bug in the framework.
    CDEErrorCodeMissingCloudSnapshot        = 208,
    
    /// There is no persistent store at the path. Ensure a store exists and try again.
    CDEErrorCodeMissingStore                = 209,
    
    /// A save or merge should only generate one type of change per object (eg insert).
    /// Multiple changes for one object were detected.
    /// Make sure merge repairs only modify each object at most once.
    CDEErrorCodeMultipleObjectChanges       = 211,
    
    /// Some parts of a multipart file are missing.
    /// Retry a bit later.
    CDEErrorCodeIncompleteMultipartFile     = 212,
    
    /// An error occurred during a Core Data operation (eg fetch)
    CDEErrorCodeCoreDataError               = 300,
    
    /// A generic networking error occurred.
    CDEErrorCodeNetworkError                = 1000,
    
    /// An error from a server was received.
    CDEErrorCodeServerError                 = 1001,
    
    /// The cloud file system could not connect.
    CDEErrorCodeConnectionError             = 1002,
    
    /// The user failed to authenticate.
    CDEErrorCodeAuthenticationFailure       = 1003,
    
    /// A sync data reset occurred.
    CDEErrorCodeSyncDataWasReset            = 2000,
};


#pragma mark Logging

typedef NS_ENUM(NSUInteger, CDELoggingLevel) {
    /// No logging.
    CDELoggingLevelNone,
    
    /// Log only errors.
    CDELoggingLevelError,
    
    /// Log warnings and errors.
    CDELoggingLevelWarning,
    
    /// Log major points in code.
    CDELoggingLevelTrace,
    
    /// Log everything.
    CDELoggingLevelVerbose
};

// Log callback support. Use CDESetLogCallback to supply a function that
// will receive all Ensembles logging.  Default log output goes to NSLog().
typedef void (*CDELogCallbackFunction)(NSString * _Nullable format, ...);
void CDESetLogCallback(CDELogCallbackFunction _Nullable callback);
extern CDELogCallbackFunction _Nullable CDECurrentLogCallbackFunction;

#define CDELog(level, ...) \
do { \
    if (CDECurrentLoggingLevel() >= level) { \
        CDECurrentLogCallbackFunction(@"  %-60s  <<<  %-70s line %d", [[NSString stringWithFormat:__VA_ARGS__] UTF8String], __PRETTY_FUNCTION__, __LINE__); \
    } \
} while (0)


/**
 Set the level of messages to be printed to the console.
 */
void CDESetCurrentLoggingLevel(NSUInteger newLevel);
NSUInteger CDECurrentLoggingLevel(void);


#pragma mark Callbacks

typedef void (^CDECodeBlock)(void);
typedef void (^CDEBooleanQueryBlock)(NSError * _Nullable error, BOOL result);
typedef void (^CDECompletionBlock)(NSError * _Nullable error);

#pragma mark Functions

void CDEDispatchCompletionBlockToMainQueue(CDECompletionBlock _Nullable block, NSError * _Nullable error);
CDECompletionBlock _Nullable CDEMainQueueCompletionFromCompletion(CDECompletionBlock _Nullable block);


#pragma mark Useful Macros

#define CDENSNullToNil(object) ((id)object == (id)[NSNull null] ? nil : object)
#define CDENilToNSNull(object) (object ? : [NSNull null])

