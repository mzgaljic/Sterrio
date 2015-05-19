//
//  SongAlbumArt.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/4/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Song;

@interface SongAlbumArt : NSManagedObject

@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSString * uniqueId;
@property (nonatomic, retain) Song *associatedSong;

@end
