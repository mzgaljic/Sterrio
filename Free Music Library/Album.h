//
//  Album.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/19/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AlbumAlbumArt, Artist, Song;

@interface Album : NSManagedObject

@property (nonatomic, retain) NSString * album_id;
@property (nonatomic, retain) NSString * albumName;
@property (nonatomic, retain) NSString * smartSortAlbumName;
@property (nonatomic, retain) NSSet *albumSongs;
@property (nonatomic, retain) Artist *artist;
@property (nonatomic, retain) AlbumAlbumArt *albumArt;
@end

@interface Album (CoreDataGeneratedAccessors)

- (void)addAlbumSongsObject:(Song *)value;
- (void)removeAlbumSongsObject:(Song *)value;
- (void)addAlbumSongs:(NSSet *)values;
- (void)removeAlbumSongs:(NSSet *)values;

@end
