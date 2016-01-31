//
//  LevenshteinDistanceItem.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/15/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LevenshteinDistanceItem : NSObject
@property (nonatomic, strong) NSString *string;
//if we're computing distances of things other than just strings. Like an album, etc.
@property (nonatomic, strong) id modelObj;
@property (nonatomic, assign) NSInteger distance;
@end
