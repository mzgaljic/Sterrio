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
@property(atomic, strong) NSString *albumArtFileName;  //overrides individual song album arts when displaying in GUI.
@property(atomic, strong) Artist *artist;
@property(atomic, strong) NSMutableArray *albumSongs;
@property(atomic, assign) int genreCode;  //overrides song genre codes within album

+ (NSArray *)loadAll;
- (BOOL)save;

@end
