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
    return [[UIImage alloc] initWithContentsOfFile:path];
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
    if(fileName){
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        NSString *artDirPath = [documentsPath stringByAppendingPathComponent:@"Album Art"];
        
        NSString *filePath = [artDirPath stringByAppendingPathComponent:fileName];
        
        return [fileManager removeItemAtPath:filePath error:nil];
    }
    return YES;
}

+ (BOOL)saveAlbumArtFileWithName:(NSString *)fileName andImage:(UIImage *)albumArtImage
{
    if(fileName){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
        
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"Album Art"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath:dataPath]){
            NSArray *keys = [NSArray arrayWithObjects:NSFilePosixPermissions,
                             NSFileProtectionKey, nil];
            NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithShort:975],
                                NSFileProtectionCompleteUntilFirstUserAuthentication, nil];
            NSDictionary *permission = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            
            //Create folder with 975 permissions
            [fileManager createDirectoryAtPath:dataPath
                   withIntermediateDirectories:YES
                                    attributes:permission
                                         error:nil];
        }
        
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
        
        BOOL success = [fileManager createFileAtPath:filePath contents:data attributes:nil];
        
        //now set permissions of this file to 777 as well
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[fileManager attributesOfItemAtPath:filePath error:nil]];
        [attributes setValue:[NSNumber numberWithShort:777]
                      forKey:NSFilePosixPermissions];
        [attributes setValue:NSFileProtectionCompleteUntilFirstUserAuthentication forKey:NSFileProtectionKey];
        return success;
    }
    return YES;
}

+ (BOOL)isAlbumArtAlreadySavedOnDisk:(NSString *)albumArtFileName
{
    if(albumArtFileName){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
        
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"Album Art"];
        dataPath = [dataPath stringByAppendingPathComponent:albumArtFileName];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        return [fileManager fileExistsAtPath:dataPath];
    }
    return YES;
}

//rarely used
+ (BOOL)renameAlbumArtFileFrom:(NSString *)original to:(NSString *)newName
{
    if(original && newName){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
        
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"Album Art"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath:dataPath])
            //file doesnt exist, operation failed
            return NO;
        
        NSString *originalFilePath = [dataPath stringByAppendingPathComponent:original];
        NSString *newFilePath = [dataPath stringByAppendingPathComponent:newName];
#warning need to also change encryption protection off when creating this new file
        return [fileManager moveItemAtPath:originalFilePath toPath:newFilePath error:nil];
    }
    return YES;
}

+ (BOOL)makeCopyOfArtWithName:(NSString *)fileName andNameIt:(NSString *)newName
{
    if(fileName && newName){
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
    return YES;
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
    image = nil;
    return newImage;
}

@end
