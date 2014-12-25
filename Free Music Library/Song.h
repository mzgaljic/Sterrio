//
//  Song.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/22/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Album, Artist, Playlist;

@interface Song : NSManagedObject

@property (nonatomic, retain) NSString * albumArtFileName;
@property (nonatomic, retain) NSNumber * associatedWithAlbum;
@property (nonatomic, retain) NSNumber * genreCode;
@property (nonatomic, retain) NSString * smartSortSongName;
@property (nonatomic, retain) NSString * song_id;
@property (nonatomic, retain) NSString * songName;
@property (nonatomic, retain) NSString * youtube_id;
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
