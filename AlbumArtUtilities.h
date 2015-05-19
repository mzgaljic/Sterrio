//
//  AlbumArtUtilities.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlbumArtUtilities : NSObject

+ (NSData *)compressedDataFromUIImage:(UIImage *)anImage;

+ (UIImage *)getImageWithoutLazyLoadingUsingNSData:(NSData *)imageData;

//image manipulation at run time
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

//fetching path to the NSCoder file which contains objects that help us update LQ album art.
+ (NSString *)pathToLqAlbumArtNSCodedFile;

@end
