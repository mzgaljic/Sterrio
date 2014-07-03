//
//  AlteredModelItem.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/3/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"
#import "Album.h"
#import "Artist.h"
//import genre's?

@interface AlteredModelItem : NSObject <NSCoding>
///Typically a song name, album name, artist name, etc...depending on how this object was initialized.
@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, assign, readonly) BOOL addedItem;

- (AlteredModelItem *)initWithAddedSong:(Song *)addedSong;
- (AlteredModelItem *)initWithAddedAlbum:(Album *)addedAlbum;
- (AlteredModelItem *)initWithAddedArtist:(Artist *)addedArtist;

- (AlteredModelItem *)initWithRemovedSong:(Song *)removedSong;
- (AlteredModelItem *)initWithRemovedAlbum:(Album *)removedAlbum;
- (AlteredModelItem *)initWithRemovedArtist:(Artist *)removedArtist;

@end
