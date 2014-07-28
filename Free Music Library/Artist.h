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
#import "NSString+smartSort.h"
#import "NSObject+ObjectUUID.h"

@interface Artist : NSObject <NSCoding>

@property(nonatomic, strong) NSString *artistName;  //note: naming conventions are restricted
@property(nonatomic, strong) NSMutableArray *allSongs;  //songs NOT associated w/ albums
@property(nonatomic, strong) NSMutableArray *allAlbums;
@property(nonatomic, strong, readonly) NSString *artistID;

+ (NSArray *)loadAll;
/**Artist objects need to be saved after being created if they are to appear in the model.*/
- (BOOL)saveArtist;
- (BOOL)deleteArtist;
- (BOOL)updateExistingArtist;

@end
