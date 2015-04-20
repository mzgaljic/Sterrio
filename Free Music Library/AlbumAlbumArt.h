//
//  AlbumAlbumArt.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/19/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Album;

@interface AlbumAlbumArt : NSManagedObject

@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSNumber * isDirty;
@property (nonatomic, retain) Album *associatedAlbum;

@end
