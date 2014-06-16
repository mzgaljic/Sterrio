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

@property(atomic, strong) NSString *songName;
@property(atomic, strong) NSString *youtubeLink;
@property(atomic, strong) NSString *albumArtPath;  //used only when this song isn't associated with an album.
@property(atomic, strong) Album *album;
@property(atomic, strong) Artist *artist;
@property(atomic, assign) int genreCode;  //album genre will override this value if this song belongs to an album!

+ (NSArray *)loadAll;
- (BOOL)save;

@end
