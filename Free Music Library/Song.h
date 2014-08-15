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
#import "NSObject+ObjectUUID.h"

@class Album;
@class Artist;

@interface Song : NSObject <NSCoding>

@property(nonatomic, strong) NSString *songName;
@property(nonatomic, strong) NSString *youtubeId;
@property(nonatomic, strong, readonly) NSString *albumArtFileName;

@property(nonatomic, strong) Artist *artist;
@property(nonatomic, strong) Album *album;
@property(nonatomic, assign) int genreCode;  //album genre will override this value if this song belongs to an album!
@property(nonatomic, assign, readonly) BOOL associatedWithAlbum;
@property(nonatomic, strong, readonly) NSString *songID;

+ (NSArray *)loadAll;
+ (void)reSortModel;

/**Song objects need to be saved after being created if they are to appear in the model.*/
- (BOOL)saveSong;
- (BOOL)deleteSong;
- (BOOL)updateExistingSong;

- (BOOL)setAlbumArt:(UIImage *)image;
- (void)removeAlbumArt;

@end