//
//  SongAlbumArt+Utilities.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/19/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "SongAlbumArt.h"

@interface SongAlbumArt (Utilities)

+ (SongAlbumArt *)createNewAlbumArtWithUIImage:(UIImage *)image withContext:(NSManagedObjectContext *)context;

- (UIImage *)imageFromImageData;

@end
