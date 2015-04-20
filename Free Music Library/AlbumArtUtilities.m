//
//  AlbumArtUtilities.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/2/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AlbumArtUtilities.h"

@implementation AlbumArtUtilities

+ (NSData *)compressedDataFromUIImage:(UIImage *)anImage
{
    if(anImage == nil)
        return nil;
    CGFloat compression = 0.95f;
    CGFloat maxCompression = 0.65f;
    int oneKB = 1000;
    int maxFileSize = 90 * oneKB;
    
    NSData *imageData = UIImageJPEGRepresentation(anImage, compression);
    if([imageData length] < maxFileSize)
        return imageData;
    
    //else we try to compress without losing too much quality
    while ([imageData length] > maxFileSize && compression > maxCompression){
        compression -= 0.1;
        imageData = UIImageJPEGRepresentation(anImage, compression);
    }
    return imageData;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    if(image == nil)
        return nil;
    UIGraphicsBeginImageContextWithOptions(newSize, NO, [UIScreen mainScreen].scale);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    image = nil;
    return newImage;
}

+ (UIImage *)getImageWithoutLazyLoadingUsingNSData:(NSData *)imageData
{
    if(imageData == nil)
        return nil;
    
    // get a data provider referencing the nsdata obj
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)imageData);
    
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

//fetching path to the NSCoder file which contains objects that help us update LQ album art.
+ (NSString *)pathToLqAlbumArtNSCodedFile
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:MZFileNameOfLqAlbumArtObjs];
    return dataPath;
}

@end
