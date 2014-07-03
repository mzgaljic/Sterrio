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
+ (BOOL)saveAlbumArtFileWithName:(NSString *)fileName;

//In-memory image manipulation
///Returns a compressed UIImage object which is the appropriate size for use with this app.
+ (UIImage *)compressAlbumArtUiImage:(UIImage *)albumArt;

@end
