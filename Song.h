//
//  Song.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/4/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Album, Artist, PlaylistItem, SongAlbumArt;

@interface Song : NSManagedObject

@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * nonDefaultArtSpecified;
@property (nonatomic, retain) NSString * smartSortSongName;
@property (nonatomic, retain) NSString * songName;
@property (nonatomic, retain) NSString * uniqueId;
@property (nonatomic, retain) NSString * youtube_id;
@property (nonatomic, retain) NSString *firstSmartChar;
@property (nonatomic, retain) Album *album;
@property (nonatomic, retain) SongAlbumArt *albumArt;
@property (nonatomic, retain) Artist *artist;
@property (nonatomic, retain) NSSet *playlistItems;
@end

@interface Song (CoreDataGeneratedAccessors)

- (void)addPlaylistItemsObject:(PlaylistItem *)value;
- (void)removePlaylistItemsObject:(PlaylistItem *)value;
- (void)addPlaylistItems:(NSSet *)values;
- (void)removePlaylistItems:(NSSet *)values;

@end
