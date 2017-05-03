//
//  PlaylistItem+Utilities.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/4/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "PlaylistItem.h"

@interface PlaylistItem (Utilities)

+ (PlaylistItem *)createNewPlaylistItemWithCorrespondingPlaylist:(Playlist *)aPlaylist
                                                            song:(Song *)aSong
                                                 indexInPlaylist:(short)index
                                                inManagedContext:(NSManagedObjectContext *)context;

- (BOOL)isEqualToPlaylistItem:(PlaylistItem *)item;

@end
