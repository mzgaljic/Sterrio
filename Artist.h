//
//  Artist.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/4/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Album, Song;

@interface Artist : NSManagedObject

@property (nonatomic, retain) NSString * artistName;
@property (nonatomic, retain) NSString * smartSortArtistName;
@property (nonatomic, retain) NSString * uniqueId;
@property (nonatomic, retain) NSSet *albums;
@property (nonatomic, retain) NSSet *standAloneSongs;
@end

@interface Artist (CoreDataGeneratedAccessors)

- (void)addAlbumsObject:(Album *)value;
- (void)removeAlbumsObject:(Album *)value;
- (void)addAlbums:(NSSet *)values;
- (void)removeAlbums:(NSSet *)values;

- (void)addStandAloneSongsObject:(Song *)value;
- (void)removeStandAloneSongsObject:(Song *)value;
- (void)addStandAloneSongs:(NSSet *)values;
- (void)removeStandAloneSongs:(NSSet *)values;

@end
