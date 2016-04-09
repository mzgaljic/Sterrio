//
//  CDEICloudFileSystem.h
//  Ensembles
//
//  Created by Drew McCormack on 20/09/13.
//  Copyright (c) 2013 Drew McCormack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDECloudFileSystem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const CDEICloudFileSystemDidDownloadFilesNotification;
extern NSString * const CDEICloudFileSystemDidMakeDownloadProgressNotification;

NS_ASSUME_NONNULL_END

@interface CDEICloudFileSystem : NSObject <CDECloudFileSystem, NSFilePresenter>

@property (nonatomic, readonly, nonnull) NSString *relativePathToRootInContainer;
@property (atomic, readonly) unsigned long long bytesRemainingToDownload;

- (nonnull instancetype)initWithUbiquityContainerIdentifier:(nullable NSString *)newIdentifier;
- (nonnull instancetype)initWithUbiquityContainerIdentifier:(nullable NSString *)newIdentifier relativePathToRootInContainer:(nullable NSString *)rootSubPath;

@end
