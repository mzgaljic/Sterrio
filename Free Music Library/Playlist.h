//
//  Playlist.h
//  Muzic
//
//  Created by Mark Zgaljic on 1/4/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Song;

@interface Playlist : NSManagedObject

@property (nonatomic, retain) NSString * playlist_id;
@property (nonatomic, retain) NSString * playlistName;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSOrderedSet *playlistSongs;
@end

@interface Playlist (CoreDataGeneratedAccessors)

- (void)insertObject:(Song *)value inPlaylistSongsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPlaylistSongsAtIndex:(NSUInteger)idx;
- (void)insertPlaylistSongs:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePlaylistSongsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPlaylistSongsAtIndex:(NSUInteger)idx withObject:(Song *)value;
- (void)replacePlaylistSongsAtIndexes:(NSIndexSet *)indexes withPlaylistSongs:(NSArray *)values;
- (void)addPlaylistSongsObject:(Song *)value;
- (void)removePlaylistSongsObject:(Song *)value;
- (void)addPlaylistSongs:(NSOrderedSet *)values;
- (void)removePlaylistSongs:(NSOrderedSet *)values;
@end
