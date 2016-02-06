//
//  DiscogsItem.h
//  Sterrio
//
//  Created by Mark Zgaljic on 5/15/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMWebRequest.h"

@interface DiscogsItem : NSObject

typedef enum {
    MatchConfidence_UNDEFINED,
    MatchConfidence_LOW,
    MatchConfidence_MEDIUM_LOW,
    MatchConfidence_MEDIUM,
    MatchConfidence_MEDIUM_HIGH,
    MatchConfidence_HIGH,
    MatchConfidence_VERY_HIGH
} MatchConfidence;

@property (nonatomic, strong) NSString *songName;
@property (nonatomic, strong) NSString *artistName;
@property (nonatomic, strong) NSString *albumName;
@property (nonatomic, strong) NSArray *featuredArtists;
@property (nonatomic, assign) int releaseYear;
@property (nonatomic, assign) MatchConfidence matchConfidence;
@property (nonatomic, strong) NSArray *formats;  //ie: Album, Vinyle, etc. Represented as NSStrings.
///if it is created locally on the device from known values, etc.
@property (nonatomic, assign) BOOL itemGuranteedCorrect;


+ (SMWebRequest *)requestForDiscogsItems:(NSString *)query;

- (BOOL)isAlbumVinylCDOrEP;
- (BOOL)isASingle;

@end
