//
//  FileIOConstants.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/12/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "FileIOConstants.h"

@implementation FileIOConstants
//model URLS
static NSURL *songsUrl = nil;
static NSURL *albumsUrl = nil;
static NSURL *artistsUrl = nil;
static NSURL *playlistsUrl = nil;
static NSURL *tempPlaylistsUrl = nil;
static NSURL *genresUrl = nil;

+ (instancetype)createSingleton
{
    static id sharedMyModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyModel = [[self alloc] init];
    });
    return sharedMyModel;
}

- (void)setSongsFileURL:(NSURL *)aUrl
{
    songsUrl = aUrl;
}

- (void)setAlbumsFileURL:(NSURL *)aUrl
{
    albumsUrl = aUrl;
}

- (void)setArtistsFileURL:(NSURL *)aUrl
{
    artistsUrl = aUrl;
}

- (void)setPlaylistsFileURL:(NSURL *)aUrl
{
    playlistsUrl = aUrl;
}

- (void)setTempPlaylistsFileURL:(NSURL *)aUrl
{
    tempPlaylistsUrl = aUrl;
}

- (void)setGenresFileURL:(NSURL *)aUrl
{
    genresUrl = aUrl;
}


- (NSURL *)songsFileURL
{
    return songsUrl;
}

- (NSURL *)albumsFileURL
{
    return albumsUrl;
}

- (NSURL *)artistsFileURL
{
    return artistsUrl;
}

- (NSURL *)playlistsFileURL
{
    return playlistsUrl;
}

- (NSURL *)tempPlaylistsFileURL
{
    return tempPlaylistsUrl;
}

- (NSURL *)genresFileURL
{
    return genresUrl;
}

@end
