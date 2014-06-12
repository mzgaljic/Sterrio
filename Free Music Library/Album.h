//
//  Album.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Artist.h"

@interface Album : NSObject <NSCoding>

@property(atomic, strong) NSString *albumName;
@property(atomic, strong) NSDate *releaseDate;
@property(atomic, strong) NSString *albumArtPath;  //overrides individual song album arts when displaying in GUI.
@property(atomic, strong) Artist *artist;
//overrides all songs genre codes within this album...this is the 'master genre code' for this album.
@property(atomic, assign) int genreCode;

@end
