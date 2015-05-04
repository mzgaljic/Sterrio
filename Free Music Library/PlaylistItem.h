//
//  PlaylistItem.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/3/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Playlist, Song;

@interface PlaylistItem : NSManagedObject

@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSString * uniqueId;
@property (nonatomic, retain) Song *song;
@property (nonatomic, retain) Playlist *playlist;

@end
