//
//  Song.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Album.h"
#import "Artist.h"

@interface Song : NSObject <NSCoding>

@property(nonatomic, strong) NSString *songName;
@property(nonatomic, strong) NSString *youtubeLink;
@property(nonatomic, strong) NSString *albumArtPath;  //used only when this song isn't associated with an album.
@property(nonatomic, strong) Album *album;
@property(nonatomic, strong) Artist *artist;
@property(nonatomic, assign) int genreCode;  //album genre will override this value if this song belongs to an album!

+ (NSArray *)loadAll;
//should be saved upon songs creation
- (BOOL)save;
- (BOOL)deleteAlbum;

@end
