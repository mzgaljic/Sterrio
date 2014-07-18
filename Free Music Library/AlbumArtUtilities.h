//
//  AlbumArtUtilities.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlbumArtUtilities : NSObject

//file IO
+ (UIImage *)albumArtFileNameToUiImage:(NSString *)albumArtFileName;
+ (BOOL)deleteAlbumArtFileWithName:(NSString *)fileName;
+ (BOOL)saveAlbumArtFileWithName:(NSString *)fileName andImage:(UIImage *)albumArtImage;
+ (BOOL)isAlbumArtAlreadySavedOnDisk:(NSString *)albumArtFileName;

//rarely used
+ (BOOL)renameAlbumArtFileFrom:(NSString *)original to:(NSString *)newName;
+ (BOOL)makeCopyOfArtWithName:(NSString *)fileName andNameIt:(NSString *)newName;

//image manipulation at run time
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@end
