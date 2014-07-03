//
//  ModelAlteredStatus.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileIOConstants.h"

@interface ModelAlteredStatus : NSObject <NSCoding>
@property (nonatomic, assign, readonly) BOOL SongModelHasChanged;
@property (nonatomic, assign, readonly) BOOL AlbumModelHasChanged;
@property (nonatomic, assign, readonly) BOOL ArtistModelHasChanged;

+ (instancetype)createSingleton;

- (void)setSongModelChangedStatus:(BOOL)modelChangedBool;
- (void)setAlbumModelChangedStatus:(BOOL)modelChangedBool;
- (void)setArtistModelChangedStatus:(BOOL)modelChangedBool;

+ (ModelAlteredStatus *)loadDataFromDisk;
- (BOOL)saveDataToDisk;

@end
