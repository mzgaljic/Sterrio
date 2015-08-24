//
//  SpotlightHelper.h
//  Sterrio
//
//  Created by Mark Zgaljic on 7/10/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SpotlightHelper : NSObject

+ (void)addSongToSpotlightIndex:(Song *)aSong;

+ (void)removeSongFromSpotlightIndex:(Song *)aSong;
+ (void)removeAlbumSongsFromSpotlightIndex:(Album *)anAlbum;
+ (void)removeArtistSongsFromSpotlightIndex:(Artist *)anArtist;

+ (void)updateSpotlightIndexForSong:(Song *)aSong;
+ (void)updateSpotlightIndexForAlbum:(Album *)anAlbum;
+ (void)updateSpotlightIndexForArtist:(Artist *)anArtist;

@end
