//
//  AlbumModelHandler.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/19/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Album+Utilities.h"
#import "Artist+Utilities.h"

@interface AlbumModelHandler : NSObject

+ (void)handleArtistChangeUsingAlbum:(Album *)album newArtist:(Artist *)artist;

@end
