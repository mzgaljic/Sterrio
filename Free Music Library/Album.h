//
//  Album.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Artist.h"
#import "Song.h"
#import "FileIOConstants.h"
#import "AlbumArtUtilities.h"

@interface Album : NSObject <NSCoding>

@property(nonatomic, strong) NSString *albumName;
@property(nonatomic, strong) NSDate *releaseDate;
@property(nonatomic, strong, readonly) NSString *albumArtFileName;  //overrides individual song album arts when displaying in GUI.
@property(nonatomic, strong) Artist *artist;
@property(nonatomic, strong) NSMutableArray *albumSongs;
@property(nonatomic, assign) int genreCode;  //overrides song genre codes within album

+ (NSArray *)loadAll;
///should be saved upon Albums creation
- (BOOL)saveAlbum;
- (BOOL)deleteAlbum;
- (BOOL)updateExistingAlbum;

- (void)setAlbumArt:(UIImage *)image;
- (BOOL)removeAlbumArt;

@end
