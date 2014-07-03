//
//  AlbumArtUtilities.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AlbumArtUtilities.h"

@implementation AlbumArtUtilities

+ (UIImage *)albumArtFileNameToUiImage:(NSString *)albumArtFileName
{
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* path = [docDir stringByAppendingPathComponent: albumArtFileName];
    return [UIImage imageWithContentsOfFile:path];
}

+ (BOOL)deleteAlbumArtFileWithName:(NSString *)fileName
{
    return NO;
}

+ (BOOL)saveAlbumArtFileWithName:(NSString *)fileName
{
    return NO;
}

+ (UIImage *)compressAlbumArtUiImage:(UIImage *)albumArt
{
    return nil;
}

@end
