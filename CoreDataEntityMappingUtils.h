//
//  CoreDataEntityMappingUtils.h
//  Sterrio
//
//  Created by Mark Zgaljic on 1/15/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataEntityMappingUtils : NSObject

+ (Album *)existingAlbumWithName:(NSString *)albumName;
+ (Artist *)existingArtistWithName:(NSString *)artistName;

@end
