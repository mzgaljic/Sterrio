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
#import "FileIOConstants.h"
#import "NSString+smartSort.h"
#import "AppEnvironmentConstants.h"

@class Album;
@class Artist;

@interface Song : NSObject <NSCoding>

@property(nonatomic, strong) NSString *songName;
@property(nonatomic, strong) NSString *youtubeLink;
@property(nonatomic, strong, readonly) NSString *albumArtFileName;

@property(nonatomic, strong) Artist *artist;
@property(nonatomic, strong) Album *album;
@property(nonatomic, assign) int genreCode;  //album genre will override this value if this song belongs to an album!
@property(nonatomic, assign, readonly) BOOL associatedWithAlbum;

+ (NSArray *)loadAll;
+ (void)reSortModel;

///should be saved upon songs creation
- (BOOL)saveSong;
- (BOOL)deleteSong;
- (BOOL)updateExistingSong;

- (BOOL)setAlbumArt:(UIImage *)image;
- (BOOL)removeAlbumArt;

@end