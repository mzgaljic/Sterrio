//
//  YTVideoAvailabilityChecker.h
//  Sterrio
//
//  Created by Mark Zgaljic on 2/24/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeletedYtVideoAlertCreator : NSObject

+ (void)createVideoDeletedAlertWithYtVideoId:(NSString *)videoId
                                        name:(NSString *)name
                                  artistName:(NSString *)artistName
                             managedObjectId:(NSManagedObjectID *)objId;

@end
