//
//  Song.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/16/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Album, Artist, Playlist;

@interface Song : NSManagedObject

@property (nonatomic, retain) NSString * albumArtFileName;
@property (nonatomic, retain) NSNumber * associatedWithAlbum;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * smartSortSongName;
@property (nonatomic, retain) NSString * song_id;
@property (nonatomic, retain) NSString * songName;
@property (nonatomic, retain) Album *album;
@property (nonatomic, retain) Artist *artist;
@property (nonatomic, retain) NSSet *playlistIAmIn;
@end

@interface Song (CoreDataGeneratedAccessors)

- (void)addPlaylistIAmInObject:(Playlist *)value;
- (void)removePlaylistIAmInObject:(Playlist *)value;
- (void)addPlaylistIAmIn:(NSSet *)values;
- (void)removePlaylistIAmIn:(NSSet *)values;

@end
