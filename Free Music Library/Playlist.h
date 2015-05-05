//
//  Playlist.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/4/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PlaylistItem;

@interface Playlist : NSManagedObject

@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSString * playlistName;
@property (nonatomic, retain) NSString * uniqueId;
@property (nonatomic, retain) NSSet *playlistItems;
@end

@interface Playlist (CoreDataGeneratedAccessors)

- (void)addPlaylistItemsObject:(PlaylistItem *)value;
- (void)removePlaylistItemsObject:(PlaylistItem *)value;
- (void)addPlaylistItems:(NSSet *)values;
- (void)removePlaylistItems:(NSSet *)values;

@end
