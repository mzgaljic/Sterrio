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
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *artDirPath = [documentsPath stringByAppendingPathComponent:@"Album Art"];
    
    NSString* path = [artDirPath stringByAppendingPathComponent: albumArtFileName];
    return [UIImage imageWithContentsOfFile:path];
}

+ (BOOL)deleteAlbumArtFileWithName:(NSString *)fileName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *artDirPath = [documentsPath stringByAppendingPathComponent:@"Album Art"];
    
    NSString *filePath = [artDirPath stringByAppendingPathComponent:fileName];
    
    return [fileManager removeItemAtPath:filePath error:nil];
}

+ (BOOL)saveAlbumArtFileWithName:(NSString *)fileName andImage:(UIImage *)albumArtImage
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"Album Art"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:dataPath])
        //Create folder
        [fileManager createDirectoryAtPath:dataPath
               withIntermediateDirectories:NO attributes:nil
                                     error:nil];
    
    NSString *filePath = [dataPath stringByAppendingPathComponent:fileName];
    
    NSData * data = UIImagePNGRepresentation(albumArtImage);
    
    return [fileManager createFileAtPath:filePath contents:data attributes:nil];
}

+ (BOOL)isAlbumArtAlreadySavedOnDisk:(NSString *)albumArtFileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"Album Art"];
    dataPath = [documentsDirectory stringByAppendingPathComponent:albumArtFileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    return [fileManager fileExistsAtPath:dataPath];
}

//rarely used
+ (BOOL)renameAlbumArtFileFrom:(NSString *)original to:(NSString *)newName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"Album Art"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:dataPath])
        //file doesnt exist, operation failed
        return NO;
    
    NSString *originalFilePath = [dataPath stringByAppendingPathComponent:original];
    NSString *newFilePath = [dataPath stringByAppendingPathComponent:newName];
    
    return [fileManager moveItemAtPath:originalFilePath toPath:newFilePath error:nil];
}

+ (BOOL)makeCopyOfArtWithName:(NSString *)fileName andNameIt:(NSString *)newName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"Album Art"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:dataPath])
        //file doesnt exist, operation failed
        return NO;

    NSString *originalFilePath = [dataPath stringByAppendingPathComponent:fileName];
    NSString *newFilePath = [dataPath stringByAppendingPathComponent:newName];
    
    return [fileManager copyItemAtPath:originalFilePath toPath:newFilePath error:nil];
}

@end
