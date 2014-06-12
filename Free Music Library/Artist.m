//
//  Artist.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Artist.h"
#define ARTIST_NAME_KEY @"artistName"

@implementation Artist
@synthesize artistName;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        self.artistName = [aDecoder decodeObjectForKey:ARTIST_NAME_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.artistName forKey:ARTIST_NAME_KEY];
}


@end
