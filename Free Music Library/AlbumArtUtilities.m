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
    //make sure file name has .jpg at the end
    NSString *lastThreeChars = [albumArtFileName substringFromIndex: [albumArtFileName length] - 4];
    if(! [lastThreeChars isEqualToString:@".jpg"])
        albumArtFileName = [NSString stringWithFormat:@"%@.jpg", albumArtFileName];
    
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *artDirPath = [documentsPath stringByAppendingPathComponent:@"Album Art"];
    NSString *path = [artDirPath stringByAppendingPathComponent: albumArtFileName];
    return  [AlbumArtUtilities getImageWithoutLazyLoadingAtPath:path];
}

+ (NSURL *)albumArtFileNameToNSURL:(NSString *)albumArtFileName
{
    //make sure file name has .jpg at the end
    NSString *lastThreeChars = [albumArtFileName substringFromIndex: [albumArtFileName length] - 4];
    if(! [lastThreeChars isEqualToString:@".jpg"])
        albumArtFileName = [NSString stringWithFormat:@"%@.jpg", albumArtFileName];
    
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *artDirPath = [documentsPath stringByAppendingPathComponent:@"Album Art"];
    NSString* path = [artDirPath stringByAppendingPathComponent: albumArtFileName];
    return [NSURL fileURLWithPath:path];
}

+ (BOOL)deleteAlbumArtFileWithName:(NSString *)fileName
{
    if(fileName){
        //make sure file name has .jpg at the end
        NSString *lastThreeChars = [fileName substringFromIndex: [fileName length] - 4];
        if(! [lastThreeChars isEqualToString:@".jpg"])
            fileName = [NSString stringWithFormat:@"%@.jpg", fileName];
        
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
    if(fileName && albumArtImage){
        //make sure file name has .jpg at the end
        NSString *lastThreeChars = [fileName substringFromIndex: [fileName length] - 4];
        if(! [lastThreeChars isEqualToString:@".jpg"])
            fileName = [NSString stringWithFormat:@"%@.jpg", fileName];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"Album Art"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath:dataPath]){
            NSArray *keys = [NSArray arrayWithObjects:NSFileProtectionKey, nil];
            NSArray *objects = [NSArray arrayWithObjects: NSFileProtectionCompleteUntilFirstUserAuthentication, nil];
            NSDictionary *permission = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            
            //Create folder with weaker encryption
            [fileManager createDirectoryAtPath:dataPath
                   withIntermediateDirectories:YES
                                    attributes:permission
                                         error:nil];
        }
        
        NSString *filePath = [dataPath stringByAppendingPathComponent:fileName];
        NSData *data = [AlbumArtUtilities dataWithCompressionOnImage:albumArtImage];
        
        BOOL success = [fileManager createFileAtPath:filePath contents:data attributes:nil];
        
        //now set encryption to a weaker value
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[fileManager attributesOfItemAtPath:filePath error:nil]];
        [attributes setValue:NSFileProtectionCompleteUntilFirstUserAuthentication forKey:NSFileProtectionKey];
        return success;
    }
    return YES;
}

+ (BOOL)isAlbumArtAlreadySavedOnDisk:(NSString *)albumArtFileName
{
    if(albumArtFileName){
        //make sure file name has .jpg at the end
        NSString *lastThreeChars = [albumArtFileName substringFromIndex: [albumArtFileName length] - 4];
        if(! [lastThreeChars isEqualToString:@".jpg"])
            albumArtFileName = [NSString stringWithFormat:@"%@.jpg", albumArtFileName];
        
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
        //make sure file names have .jpg at the end
        NSString *lastThreeChars = [original substringFromIndex: [original length] - 4];
        if(! [lastThreeChars isEqualToString:@".jpg"])
            original = [NSString stringWithFormat:@"%@.jpg", original];
        
        lastThreeChars = [newName substringFromIndex: [newName length] - 4];
        if(! [lastThreeChars isEqualToString:@".jpg"])
            newName = [NSString stringWithFormat:@"%@.jpg", newName];
        
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
        
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"Album Art"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath:dataPath])
            //file doesnt exist, operation failed
            return NO;
        
        NSString *originalFilePath = [dataPath stringByAppendingPathComponent:original];
        NSString *newFilePath = [dataPath stringByAppendingPathComponent:newName];
        
        BOOL success = [fileManager moveItemAtPath:originalFilePath toPath:newFilePath error:nil];
        //now set encryption to a weaker value
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[fileManager attributesOfItemAtPath:newFilePath error:nil]];
        [attributes setValue:NSFileProtectionCompleteUntilFirstUserAuthentication forKey:NSFileProtectionKey];
        return success;
    }
    return YES;
}

+ (BOOL)makeCopyOfArtWithName:(NSString *)fileName andNameIt:(NSString *)newName
{
    if(fileName && newName){
        //make sure file names have .jpg at the end
        NSString *lastThreeChars = [fileName substringFromIndex: [fileName length] - 4];
        if(! [lastThreeChars isEqualToString:@".jpg"])
            fileName = [NSString stringWithFormat:@"%@.jpg", fileName];
        
        lastThreeChars = [newName substringFromIndex: [newName length] - 4];
        if(! [lastThreeChars isEqualToString:@".jpg"])
            newName = [NSString stringWithFormat:@"%@.jpg", newName];
        
    
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
        
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"Album Art"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath:dataPath])
            //file doesnt exist, operation failed
            return NO;
        
        NSString *originalFilePath = [dataPath stringByAppendingPathComponent:fileName];
        NSString *newFilePath = [dataPath stringByAppendingPathComponent:newName];
        
        BOOL success = [fileManager copyItemAtPath:originalFilePath toPath:newFilePath error:nil];
        //now set encryption to a weaker value
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[fileManager attributesOfItemAtPath:newFilePath error:nil]];
        [attributes setValue:NSFileProtectionCompleteUntilFirstUserAuthentication forKey:NSFileProtectionKey];
        return success;
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


//ideally improve this to eventually be async like this:
//http://stackoverflow.com/questions/5266272/non-lazy-image-loading-in-ios
+ (UIImage *)getImageWithoutLazyLoadingAtPath:(NSString *)path
{
    //make sure file name has .jpg at the end
    NSString *lastThreeChars = [path substringFromIndex: [path length] - 4];
    if(! [lastThreeChars isEqualToString:@".jpg"])
        path = [NSString stringWithFormat:@"%@.jpg", path];
    
    // get a data provider referencing the relevant file
    CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename([path UTF8String]);

    if(dataProvider == NULL)
        return nil;
    
    // use the data provider to get a CGImage; release the data provider
    CGImageRef image = CGImageCreateWithJPEGDataProvider(dataProvider,
                                                         NULL,
                                                         NO,
                                                         kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    // make a bitmap context of a suitable size to draw to, forcing decode
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    unsigned char *imageBuffer = (unsigned char *)malloc(width*height*4);
    
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef imageContext =
    CGBitmapContextCreate(imageBuffer, width, height, 8, width*4, colourSpace,
                          kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    
    CGColorSpaceRelease(colourSpace);
    
    // draw the image to the context, release it
    CGContextDrawImage(imageContext, CGRectMake(0, 0, width, height), image);
    CGImageRelease(image);
    
    // now get an image ref from the context
    CGImageRef outputImage = CGBitmapContextCreateImage(imageContext);
    
    // post that off to the main thread, where you might do something like
    // [UIImage imageWithCGImage:outputImage]
    UIImage *returnImg = [UIImage imageWithCGImage:outputImage];
    // clean up
    CGImageRelease(outputImage);
    CGContextRelease(imageContext);
    free(imageBuffer);

    return returnImg;
}

#pragma mark -File compression
+ (NSData *)dataWithCompressionOnImage:(UIImage *)compressMe
{
    CGFloat compression = 0.95f;
    CGFloat maxCompression = 0.5f;
    int oneKB = 1000;
    int maxFileSize = 100 * oneKB;
    
    NSData *imageData = UIImageJPEGRepresentation(compressMe, compression);
    if([imageData length] < maxFileSize)
        return imageData;
    
    //else we try to compress without losing too much quality
    while ([imageData length] > maxFileSize && compression > maxCompression){
        compression -= 0.1;
        imageData = UIImageJPEGRepresentation(compressMe, compression);
    }
    return imageData;
}

//fetching path to the NSCoder file which contains objects that help us update LQ album art.
+ (NSString *)pathToLqAlbumArtNSCodedFile
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:MZFileNameOfLqAlbumArtObjs];
    return dataPath;
}

@end
