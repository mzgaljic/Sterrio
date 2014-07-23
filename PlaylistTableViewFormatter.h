//
//  PlaylistTableViewFormatter.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/22/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Playlist.h"
#import "PreferredFontSizeUtility.h"

@interface PlaylistTableViewFormatter : NSObject

+ (NSAttributedString *)formatPlaylistLabelUsingPlaylist:(Playlist *)aPlaylistInstance;

+ (float)preferredPlaylistCellHeight;

+ (float)nonBoldPlaylistLabelFontSize;
+ (BOOL)playlistNameIsBold;

@end
