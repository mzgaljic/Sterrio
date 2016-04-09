//
//  CDEFileDownloadOperation.h
//  Ensembles iOS
//
//  Created by Drew McCormack on 01/03/14.
//  Copyright (c) 2014 The Mental Faculty B.V. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDEAsynchronousOperation.h"
#import "CDEDefines.h"

@interface CDEFileDownloadOperation : CDEAsynchronousOperation

@property (nonatomic, copy, readonly, nonnull) NSURLRequest *request;
@property (nonatomic, copy, readonly, nonnull) NSString *localPath;
@property (nonatomic, copy, readwrite, nullable) CDECompletionBlock completion;

- (nonnull instancetype)initWithURLRequest:(nonnull NSURLRequest *)newRequest localPath:(nonnull NSString *)path;

@end
