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
    MatchConfidence_LOW,
    MatchConfidence_HIGH
} MatchConfidence;

@property (nonatomic, strong) NSString *songName;
@property (nonatomic, strong) NSString *artistName;
@property (nonatomic, strong) NSString *albumName;
@property (nonatomic, assign) int releaseYear;
@property (nonatomic, assign) MatchConfidence matchConfidence;

+ (SMWebRequest *)requestForDiscogsItems:(NSString *)query;

@end
