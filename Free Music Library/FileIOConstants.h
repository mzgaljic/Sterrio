//
//  FileIOConstants.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/12/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileIOConstants : NSObject

//initialization
+ (instancetype)createSingleton;
- (void)setSongsFileURL:(NSURL *)aUrl;
- (void)setAlbumsFileURL:(NSURL *)aUrl;
- (void)setArtistsFileURL:(NSURL *)aUrl;
- (void)setPlaylistsFileURL:(NSURL *)aUrl;
- (void)setTempPlaylistsFileURL:(NSURL *)aUrl;
- (void)setGenresFileURL:(NSURL *)aUrl;

//using the initialized singletons
- (NSURL *)songsFileURL;
- (NSURL *)albumsFileURL;
- (NSURL *)artistsFileURL;
- (NSURL *)playlistsFileURL;
- (NSURL *)tempPlaylistsFileURL;
- (NSURL *)genresFileURL;

@end
