//
//  SongItemViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Song.h"
#import "Album.h"
#import "Artist.h"
#import "Playlist.h"

@interface SongItemViewController : UIViewController
///only applicable when picking songs from lists (not making music queue's on the fly)
@property (assign, nonatomic) int songNumberInSongCollection;
///only applicable when picking songs from lists (not making music queue's on the fly)
@property (assign, nonatomic) int totalSongsInCollection;

///new item played by the user, thereby erasing any queue's. Nil when value is no longer 'current'.
@property (strong, nonatomic) Song *aNewSong;
///new item played by the user, thereby erasing any queue's. Nil when value is no longer 'current'.
@property (strong, nonatomic) Album *aNewAlbum;
///new item played by the user, thereby erasing any queue's. Nil when value is no longer 'current'.
@property (strong, nonatomic) Artist *aNewArtist;
///new item played by the user, thereby erasing any queue's. Nil when value is no longer 'current'.
@property (strong, nonatomic) Playlist *aNewPlaylist;

//GUI vars


@end
