//
//  Artist.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"
#import "FileIOConstants.h"
#import "AppEnvironmentConstants.h"

@interface Artist : NSObject <NSCoding>

@property(nonatomic, strong) NSString *artistName;  //note: naming conventions are restricted
@property(nonatomic, strong) NSMutableArray *allSongs;  //songs NOT associated w/ albums
@property(nonatomic, strong) NSMutableArray *allAlbums;

+ (NSArray *)loadAll;
///should be saved upon Artists creation
- (BOOL)saveArtist;
- (BOOL)deleteArtist;
- (BOOL)updateExistingArtist;

@end
