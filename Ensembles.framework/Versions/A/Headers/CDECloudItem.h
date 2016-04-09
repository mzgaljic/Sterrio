//
//  CDECloudItem.h
//  Ensembles iOS
//
//  Created by Thomas on 14/11/2015.
//  Copyright © 2015 The Mental Faculty B.V. All rights reserved.
//

@protocol CDECloudItem <NSObject>

@property (copy, nonnull) NSString *path;
@property (copy, nonnull) NSString *name;
@property (readonly) BOOL canContainChildren;

@end
