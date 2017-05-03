//
//  EnsembleDelegate.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/2/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EnsembleDelegate : NSObject <CDEPersistentStoreEnsembleDelegate>

+ (instancetype)sharedInstance;

@end
