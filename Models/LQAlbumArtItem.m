//
//  LQAlbumArtItem.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/17/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "LQAlbumArtItem.h"


NSString * const LQ_Album_Item_Song_ID_Key = @"song id key for low quality album art";
@implementation LQAlbumArtItem

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.songId forKey:LQ_Album_Item_Song_ID_Key];
}

-(id)initWithCoder:(NSCoder *)aCoder
{
    if(self = [super init]){
        self.songId = [aCoder decodeObjectForKey:LQ_Album_Item_Song_ID_Key];
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if(self == object)
        return YES;
    
    if ([object isKindOfClass:[LQAlbumArtItem class]]) {
        LQAlbumArtItem *otherItem = (LQAlbumArtItem *)object;
        if([self.songId isEqualToString:otherItem.songId])
            return YES;
    }
    
    return NO;
}

@end
