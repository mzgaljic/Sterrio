//
//  AddToPlaylist.h
//  Sterrio
//
//  Created by Mark Zgaljic on 5/21/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataCustomTableViewController.h"

/**
 * Present this to the user when you'd like to let them add an entity (Song, Album, Playlist)
 * to an existing or new playlist.
 */
@interface AddToPlaylistViewController : CoreDataCustomTableViewController

- (instancetype)initWithSong:(Song *)aSong;
//- (instancetype)initWithAlbum:(Album *)anAlbum;
//- (instancetype)initWithPlaylist:(Playlist *)aPlaylist;

@end
