//
//  SongAlbumArt+Utilities.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/19/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "SongAlbumArt+Utilities.h"
#import "AlbumArtUtilities.h"
#import "NSObject+ObjectUUID.h"

@implementation SongAlbumArt (Utilities)

NSString * const IMAGE_PROPERTY_KEY = @"image";

+ (SongAlbumArt *)createNewAlbumArtWithUIImage:(UIImage *)image withContext:(NSManagedObjectContext *)context
{
    SongAlbumArt *albumArt = [NSEntityDescription insertNewObjectForEntityForName:@"SongAlbumArt"
                                                       inManagedObjectContext:context];
    albumArt.albumArt_id = [[NSObject UUID] copy];
    albumArt.image = [AlbumArtUtilities compressedDataFromUIImage:image];
    return albumArt;
}

- (UIImage *)imageFromImageData
{
    [self willAccessValueForKey:IMAGE_PROPERTY_KEY];
    NSData *imageAsData = [self image];
    [self didAccessValueForKey:IMAGE_PROPERTY_KEY];
    
    return [AlbumArtUtilities getImageWithoutLazyLoadingUsingNSData:imageAsData];
}


@end
