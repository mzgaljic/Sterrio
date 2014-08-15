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
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
    
    return [[UIImage alloc] initWithData:data];
}

+ (NSURL *)albumArtFileNameToNSURL:(NSString *)albumArtFileName
{
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *artDirPath = [documentsPath stringByAppendingPathComponent:@"Album Art"];
    NSString* path = [artDirPath stringByAppendingPathComponent: albumArtFileName];
    return [NSURL fileURLWithPath:path];
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
               withIntermediateDirectories:NO attributes:nil error:nil];
    
    NSString *filePath = [dataPath stringByAppendingPathComponent:fileName];
    
    //this block of code is able to save the PNG every time. even if the data is corrupted (good so i dont need to avoid broken NSurls)
    UIImage *originalImage = albumArtImage;
    CGSize destinationSize = CGSizeMake(albumArtImage.size.width, albumArtImage.size.height); // Give your Desired thumbnail Size
    UIGraphicsBeginImageContext(destinationSize);
    [originalImage drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    NSData *data = UIImagePNGRepresentation(newImage);
    UIGraphicsEndImageContext();
    
    //NSData * data = UIImagePNGRepresentation(albumArtImage);
    
    return [fileManager createFileAtPath:filePath contents:data attributes:nil];
}

+ (BOOL)isAlbumArtAlreadySavedOnDisk:(NSString *)albumArtFileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"Album Art"];
    dataPath = [dataPath stringByAppendingPathComponent:albumArtFileName];
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

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
