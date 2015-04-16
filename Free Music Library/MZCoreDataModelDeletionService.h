//
//  MZCoreDataModelDeletionService.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/10/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AlbumArtUtilities.h"
#import "Album.h"
#import "Artist.h"
#import "Song+Utilities.h"

@interface MZCoreDataModelDeletionService : NSObject

+ (void)prepareSongForDeletion:(Song *)songToDelete;

//mainly exposed for song edits in the song editor VC.
+ (void)removeSongFromItsAlbum:(Song *)aSong;
+ (void)removeSongFromItsArtist:(Song *)aSong;

@end
