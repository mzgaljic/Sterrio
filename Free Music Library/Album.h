//
//  Album.h
//  Muzic
//
//  Created by Mark Zgaljic on 1/4/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Artist, Song;

@interface Album : NSManagedObject

@property (nonatomic, retain) NSString * album_id;
@property (nonatomic, retain) NSString * albumArtFileName;
@property (nonatomic, retain) NSString * albumName;
@property (nonatomic, retain) NSNumber * genreCode;
@property (nonatomic, retain) NSString * smartSortAlbumName;
@property (nonatomic, retain) NSSet *albumSongs;
@property (nonatomic, retain) Artist *artist;
@end

@interface Album (CoreDataGeneratedAccessors)

- (void)addAlbumSongsObject:(Song *)value;
- (void)removeAlbumSongsObject:(Song *)value;
- (void)addAlbumSongs:(NSSet *)values;
- (void)removeAlbumSongs:(NSSet *)values;

@end
