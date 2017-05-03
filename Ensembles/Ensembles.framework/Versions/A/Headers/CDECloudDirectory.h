//
//  CDEDirectory.h
//  Ensembles
//
//  Created by Drew McCormack on 4/12/13.
//  Copyright (c) 2013 Drew McCormack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDECloudItem.h"

@interface CDECloudDirectory : NSObject<CDECloudItem>

@property (strong, nonnull) NSArray<CDECloudItem> *contents;

@end
