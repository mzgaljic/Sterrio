//
//  SongModelHandler.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/19/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Album+Utilities.h"
#import "Song+Utilities.h"
#import "Artist+Utilities.h"
#import "AlbumArtUtilities.h"

@interface SongModelHandler : NSObject

+ (void)handleAlbumChange:(Song *)selfSong newAlbum:(Album *)newAlbum;

+ (void)handleArtistChange:(Song *)selfSong newArtist:(Artist *)artist;

@end
