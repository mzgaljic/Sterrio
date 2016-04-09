//
//  CDEFileUploadOperation.h
//  Ensembles Mac
//
//  Created by Drew McCormack on 01/03/14.
//  Copyright (c) 2014 Drew McCormack. All rights reserved.
//

#import "CDEAsynchronousOperation.h"
#import "CDEDefines.h" 

@interface CDEFileUploadOperation : CDEAsynchronousOperation

@property (nonatomic, copy, readonly, nonnull) NSString *localPath;
@property (nonatomic, copy, readonly, nonnull) NSURLRequest *request;
@property (nonatomic, copy, readwrite, nullable) CDECompletionBlock completion;

- (nonnull instancetype)initWithURLRequest:(nonnull NSURLRequest *)urlRequest localPath:(nonnull NSString *)path;

@end
