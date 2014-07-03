//
//  AlteredModelItem.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AlteredModelItem.h"
#define IDENTIFIER_KEY @"identifier"
#define ADDED_ITEM_KEY @"addedItem"

@implementation AlteredModelItem
@synthesize identifier = _identifier, addedItem = _addedItem;

- (AlteredModelItem *)initWithAddedSong:(Song *)addedSong
{
    _identifier = addedSong.songName;
    _addedItem = YES;
    return self;
}

- (AlteredModelItem *)initWithAddedAlbum:(Album *)addedAlbum
{
    _identifier = addedAlbum.albumName;
    _addedItem = YES;
    return self;
}

- (AlteredModelItem *)initWithAddedArtist:(Artist *)addedArtist
{
    _identifier = addedArtist.artistName;
    _addedItem = YES;
    return self;
}



- (AlteredModelItem *)initWithRemovedSong:(Song *)removedSong
{
    _identifier = removedSong.songName;
    _addedItem = NO;
    return self;
}

- (AlteredModelItem *)initWithRemovedAlbum:(Album *)removedAlbum
{
    _identifier = removedAlbum.albumName;
    _addedItem = NO;
    return self;
}

- (AlteredModelItem *)initWithRemovedArtist:(Artist *)removedArtist
{
    _identifier = removedArtist.artistName;
    _addedItem = NO;
    return self;
}

//-----------------NSCoding stuff---------------
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        _identifier = [aDecoder decodeObjectForKey:IDENTIFIER_KEY];
        _addedItem = [aDecoder decodeBoolForKey:ADDED_ITEM_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_identifier forKey:IDENTIFIER_KEY];
    [aCoder encodeBool:_addedItem forKey:ADDED_ITEM_KEY];
}

//loading and saving code will be done with the root object (AlteredModelQueue's).

@end
