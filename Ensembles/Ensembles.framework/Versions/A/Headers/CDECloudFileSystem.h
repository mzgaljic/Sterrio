//
//  CDECloudFileSystem.h
//  Ensembles
//
//  Created by Drew McCormack on 4/12/13.
//  Copyright (c) 2013 Drew McCormack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDEDefines.h"

typedef void (^CDEFileExistenceCallback)(BOOL exists, BOOL isDirectory, NSError * _Nullable error);
typedef void (^CDEDirectoryExistenceCallback)(BOOL exists, NSError * _Nullable error);
typedef void (^CDEDirectoryContentsCallback)(NSArray * _Nullable contents, NSError * _Nullable error);
typedef void (^CDEFetchUserIdentityCallback)(id <NSObject, NSCoding, NSCopying> _Nullable token, NSError * _Nullable error);

/**
 A cloud file system facilitates data transfer between devices.
 
 Any backend that can store files at paths can be used. This could be a key-value store like S3, or a true file system like WebDAV. Even direct connections like the multipeer connectivity in iOS 7 can be used as a cloud file system when coupled with a local cache of files.
 */
@protocol CDECloudFileSystem <NSObject>


@required

///
/// @name Connection
///

/**
 Whether ensembles is considered to be connected to the file system, and thereby can make requests.
 
 Different backends may interpret this differently. What should be true is that if `isConnected` returns `YES`, ensembles can attempt to make file transactions.
 
 If this property is `NO`, ensembles will invoke the `connect:` method before attempting further file operations.
 */
@property (nonatomic, assign, readonly) BOOL isConnected;

/**
 Fetches a token representing the user of the cloud file system.
 
 Often this will be the user or login name.
 
 @param completion The callback block, which passes back the user token. The last argument is an `NSError`, which should be `nil` if successful.
 */
- (void)fetchUserIdentityWithCompletion:(nullable CDEFetchUserIdentityCallback)completion;

/**
 Attempts to connect to the cloud backend.
 
 If successful, the completion block should be called on the main thread with argument of `nil`. If the connection fails, an `NSError` instance should be passed to the completion block.
 
 @param completion The completion block called when the connection succeeds or fails.
 */
- (void)connect:(nullable CDECompletionBlock)completion;

///
/// @name File Existence
///

/**
 Determines whether a file exists in the cloud, and if so, whether it is a standard file or a directory.
 
 Upon determining whether the file exists, the completion block should be called on the main thread.
 
 @param block The completion block, which takes `BOOL` arguments for whether the file exists and whether it is a directory. The last argument is an `NSError`, which should be `nil` if successful.
 */
- (void)fileExistsAtPath:(nonnull NSString *)path completion:(nullable CDEFileExistenceCallback)block;


@optional

///
/// @name Directory Existence
///

/**
 Determines whether a directory exists in the cloud.
 
 Upon determining whether the directory exists, the completion block should be called on the main thread.
 
 This method is optional, and is provided as a potential optimization for certain backends (eg zip). If it is available, it will be used; otherwise, the fileExistsAtPath:completion: method will be used instead.
 
 @param block The completion block, which takes two arguments. The first is a `BOOL` and indicates whether the directory exists. The second argument is an `NSError`, which should be `nil` if successful.
 */
- (void)directoryExistsAtPath:(nonnull NSString *)path completion:(nullable CDEDirectoryExistenceCallback)block;


@required

///
/// @name Working with Directories
///

/**
 Creates a directory at a given path.
 
 The completion block should be called on the main thread when the creation concludes, passing an error or `nil`.
 
 @param block The completion block, which takes one argument, an `NSError`. It should be `nil` upon success.
 */
- (void)createDirectoryAtPath:(nonnull NSString *)path completion:(nullable CDECompletionBlock)block;

/**
 Determines the contents of a directory at a given path.
 
 The completion block has an `NSArray` as its first parameter. The array should contain `CDECloudFile` and `CDECloudDirectory` objects. The completion block should should be called on the main thread.
 
 @param block The completion block, which takes two arguments. The first is an array of file/directory objects, and the second is an `NSError`. It should be `nil` upon success.
 */
- (void)contentsOfDirectoryAtPath:(nonnull NSString *)path completion:(nullable CDEDirectoryContentsCallback)block;

///
/// @name Deleting Files and Directories
///

/**
 Deletes a file or directory.
 
 The completion block takes and `NSError`, which should be `nil` upon successful completion. The block should be called on the main thread.
 
 @param block The completion block, which takes one argument, an `NSError`.
 */
- (void)removeItemAtPath:(nonnull NSString *)fromPath completion:(nullable CDECompletionBlock)block;

///
/// @name Transferring Files
///

/**
 Uploads a local file to the cloud file system.
 
 The completion block takes an `NSError`, which should be `nil` upon successful completion. The block should be called on the main thread.
 
 @param fromPath The path to the file on the device.
 @param toPath The path of the file in the cloud file system.
 @param block The completion block, which takes one argument, an `NSError`.
 */
- (void)uploadLocalFile:(nonnull NSString *)fromPath toPath:(nonnull NSString *)toPath completion:(nullable CDECompletionBlock)block;

/**
 Downloads a cloud file to the local file system.
 
 The completion block takes an `NSError`, which should be `nil` upon successful completion. The block should be called on the main thread.
 
 @param fromPath The path of the file in the cloud file system.
 @param toPath The path to the file on the device.
 @param block The completion block, which takes one argument, an `NSError`.
 */
- (void)downloadFromPath:(nonnull NSString *)fromPath toLocalFile:(nonnull NSString *)toPath completion:(nullable CDECompletionBlock)block;


@optional

///
/// @name Batch Operations
///

/**
 If the `uploadLocalFiles:toPaths:completion:` method is implemented, this property can be used to set the maximum number of files that are uploaded at once.
 
 If not provided, a default value will be used.
 */
@property (nonatomic, assign, readonly) NSUInteger fileUploadMaximumBatchSize;

/**
 If the `downloadFromPaths:toLocalFiles:completion:` method is implemented, this property can be used to set the maximum number of files that are downloaded at once.
 
 If not provided, a default value will be used.
 */
@property (nonatomic, assign, readonly) NSUInteger fileDownloadMaximumBatchSize;

/**
 Uploads local files to the cloud file system.
 
 This method will be called to upload files if it is available. It can be used to more efficiently upload multiple items at once.
 
 The completion block takes an `NSError`, which should be `nil` upon successful completion. The block should be called on the main thread.
 
 @param fromPath The paths to the files on the device.
 @param toPaths The paths of the files in the cloud file system.
 @param block The completion block, which takes one argument, an `NSError`.
 */
- (void)uploadLocalFiles:(nonnull NSArray<NSString *> *)fromPaths toPaths:(nonnull NSArray<NSString *> *)toPaths completion:(nullable CDECompletionBlock)block;

/**
 Downloads files from cloud file system.
 
 This method will be called to download files if it is available. It can be used to more efficiently download multiple items at once.
 
 The completion block takes an `NSError`, which should be `nil` upon successful completion. The block should be called on the main thread.
 
 @param fromPaths The paths of the files in the cloud file system.
 @param toPaths The paths to the files on the device.
 @param block The completion block, which takes one argument, an `NSError`.
 */
- (void)downloadFromPaths:(nonnull NSArray<NSString *> *)fromPaths toLocalFiles:(nonnull NSArray<NSString *> *)toPaths completion:(nullable CDECompletionBlock)block;

/**
 Deletes one or more files or directories.
 
 This method will be called to remove items if it is available. It can be used to more efficiently delete multiple items at once.
 
 If this method is not implemented, the framework will fallback to repeeatedly calling the method to remove a single item.
 
 The completion block takes and `NSError`, which should be `nil` upon successful completion. The block should be called on the main thread.
 
 @param paths Array of paths for the items to be removed.
 @param block The completion block, which takes one argument, an `NSError`.
 */
- (void)removeItemsAtPaths:(nonnull NSArray<NSString *> *)paths completion:(nullable CDECompletionBlock)block;

///
/// @name Initial Setup
///

/**
 An optional method which can be implemented to perform initialization when the ensemble leeches.
 
 For example, if the root directory of the file system needs to be created, this would be a good time to do that.
 
 The completion block takes an `NSError`, which should be `nil` upon successful completion. The block should be called on the main thread.
 
 @param block The completion block, which takes one argument, an `NSError`.
 */
- (void)performInitialPreparation:(nullable CDECompletionBlock)completion;

///
/// @name Priming for Activity
///

/**
 An optional method which can be implemented to prepare for some activity, like merging or leeching.
 
 Many backends can be made more efficient by fetching and caching all server data, rather than running individual
 queries. If this is the case, this method can be used to update the cache, before requests are made for files.
  
 The completion block takes an `NSError`, which should be `nil` upon successful completion. The block should be called on the main thread.
 
 @param block The completion block, which takes one argument, an `NSError`.
 */
- (void)primeForActivityWithCompletion:(nullable CDECompletionBlock)completion;


///
/// @name Repair
///

/**
 An optional method which can be implemented to perform any repairs that are needed prior to merging.
 
 Eg. Systems like iCloud and Dropbox can sometimes create duplicate files or folders. This is a good place to 'fix' that.
 
 The completion block takes an `NSError`, which should be `nil` upon successful completion. The block should be called on the main thread.
 
 @param ensembleDir Path to the directory of the ensemble.
 @param block The completion block, which takes one argument, an `NSError`.
 */
- (void)repairEnsembleDirectory:(nonnull NSString *)ensembleDir completion:(nullable CDECompletionBlock)completion;


@end
