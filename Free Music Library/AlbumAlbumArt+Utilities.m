//
//  AlbumAlbumArt+Utilities.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/19/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "AlbumAlbumArt+Utilities.h"
#import <ImageIO/ImageIO.h>
#import <UIImage+FX.h>
#import "AlbumArtUtilities.h"
#import "SongAlbumArt+Utilities.h"

@implementation AlbumAlbumArt (Utilities)

- (UIImage *)imageWithSize:(CGSize)size
{
    if(CGSizeEqualToSize(size, CGSizeZero))
        return nil;
    
    NSNumber *isDirtyNum = [self isDirty];
    BOOL isDirty = [isDirtyNum boolValue];
    BOOL currentImgSizeTooSmall = NO;
    CGSize currentSize = [self sizeOfCurrentAlbumArt];
    if(size.width > currentSize.width)
        currentImgSizeTooSmall = YES;
    
    if(isDirty || currentImgSizeTooSmall || self.image == nil)
    {
        //regenerate the collage
        UIImage *collageImage = [self collageImageAtSize:size];
        if(collageImage == nil){
            self.isDirty = @NO;
            return nil;
        }
        
        self.image = [AlbumArtUtilities compressedDataFromUIImage:collageImage];
        self.isDirty = @NO;
        return collageImage;
    }
    else
        return [AlbumArtUtilities getImageWithoutLazyLoadingUsingNSData:self.image];
}

//collage code...only produces a collage image if there are 4 songs with valid and distinct album art.
//otherwise a singe image is returned if there is between [1, 3] images to choose from.
//if no images exist to chose from, nil is returned.
- (UIImage *)collageImageAtSize:(CGSize)size
{
    NSArray *albumSongs = [self.associatedAlbum.albumSongs allObjects];
    NSArray *albumSongsWithUniqueArt = [self removeSongsWithoutUniqueArtGivenSongArray:albumSongs];
    if(albumSongs.count == 0 || albumSongsWithUniqueArt.count == 0)
        return nil;
    
    if(albumSongsWithUniqueArt.count >= 1 && albumSongsWithUniqueArt.count < 4)
    {
        //not enough pics to make a collage, just return first songs art in array.
        Song *firstSong = albumSongsWithUniqueArt[0];
        return [firstSong.albumArt imageFromImageData];
    }

    NSIndexSet *randomIndexes = [self generateIndexSetWithMinIndexInclusive:0
                                                          maxIndexInclusive:(int)albumSongsWithUniqueArt.count-1
                                                              maxIndexCount:4];
    NSArray *randomSongs = [self generateArrayFromArray:albumSongs usingIndexSet:randomIndexes];

    CGSize oneHalf = CGSizeMake(size.width/2, size.height/2);
    
    if(randomSongs.count >= 4)
    {
        //create context
        CGSize endImageSize = size;
        UIGraphicsBeginImageContextWithOptions(endImageSize, NO, [UIScreen mainScreen].scale);
        
        //stop after 4 songs!!
        for(int i = 0; i < randomSongs.count && i <= 3; i++)
        {
            Song *anAlbumSong = randomSongs[i];
            UIImage *someImg = [anAlbumSong.albumArt imageFromImageData];
            if(! [self isImageAlreadySquare:someImg]){
                //crops square in center of a wide or tall image.
                someImg = [self squareImageFromImage:someImg scaledToSize:oneHalf.width];
            }
            
            // draw image into this context
            [someImg drawInRect:[self imageDrawRectForImageCount:i +1 relativeSize:oneHalf]];
        }
        
        UIImage *endImage = UIGraphicsGetImageFromCurrentImageContext();
        //cleanup
        UIGraphicsEndImageContext();
        return endImage;
    }

    return nil;
}


- (CGRect)imageDrawRectForImageCount:(int)count relativeSize:(CGSize)size
{
    switch (count)
    {
        case 1:
            return [self topLeftCornerRectGivenRelativeSize:size];
        case 2:
            return [self topRightCornerRectGivenRelativeSize:size];
        case 3:
            return [self bottomLeftCornerRectGivenRelativeSize:size];
        case 4:
            return [self bottomRightCornerRectGivenRelativeSize:size];
        default:
            return CGRectNull;
    }
}

//based on the 1/4 model.
- (CGRect)topLeftCornerRectGivenRelativeSize:(CGSize)relative
{
    return CGRectMake(0, 0, relative.width, relative.height);
}
- (CGRect)topRightCornerRectGivenRelativeSize:(CGSize)relative
{
    return CGRectMake(relative.width, 0, relative.width, relative.height);
}
- (CGRect)bottomLeftCornerRectGivenRelativeSize:(CGSize)relative
{
    return CGRectMake(0, relative.height, relative.width, relative.height);
}
- (CGRect)bottomRightCornerRectGivenRelativeSize:(CGSize)relative
{
    return CGRectMake(relative.width, relative.height, relative.width, relative.height);
}

-  (CGSize)sizeOfCurrentAlbumArt
{
    NSData *imgdata = self.image;
    if(self.image == nil)
        return CGSizeZero;

    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef) imgdata, NULL);
    if (imageSource == NULL) {
        return CGSizeZero;
    }
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO], (NSString *)kCGImageSourceShouldCache,
                             nil];
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource,
                                                                         0,
                                                                         (CFDictionaryRef)options);
    CGSize pixelSize;
    if (imageProperties) {
        NSNumber *width = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
        NSNumber *height = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
        pixelSize = CGSizeMake([width intValue], [height intValue]);
        CFRelease(imageProperties);
    }
    CFRelease(imageSource);
    float scale = [UIScreen mainScreen].scale;
    CGSize pointSize = CGSizeMake(pixelSize.width/scale, pixelSize.height/scale);
    return pointSize;
}

- (NSIndexSet *)generateIndexSetWithMinIndexInclusive:(int)min
                                    maxIndexInclusive:(int)max
                                        maxIndexCount:(int)num
{
    if(num > max+1)
        num = max;
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    while(indexSet.count != num){
        int randomIndex = arc4random() % (max - min+1) + min;
        [indexSet addIndex:randomIndex];
    }
    
    return indexSet;
}

- (NSArray *)generateArrayFromArray:(NSArray *)source usingIndexSet:(NSIndexSet *)indexSet
{
    NSMutableArray *array = [NSMutableArray array];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [array addObject: [source objectAtIndex:idx]];
    }];
    return array;
}

- (NSArray *)removeSongsWithoutUniqueArtGivenSongArray:(NSArray *)arrayOfSongs
{
    NSMutableArray *returnArray = [NSMutableArray array];
    for(Song *someSong in arrayOfSongs)
    {
        if(someSong.albumArt){
            //song has valid album art! Now lets check if its (most likely) the exact same image
            //as another songs album art already in the array. If so, ignore it as its logically
            //(not physically) the same image.
            
            NSUInteger dataLength1 = someSong.albumArt.image.length;
            BOOL verySimilarMatch = NO;
            for(Song *aSong in returnArray)
            {
                NSUInteger dataLength2 = aSong.albumArt.image.length;
                if(dataLength1 == dataLength2){
                    verySimilarMatch = YES;
                    break;
                }
            }
            if(! verySimilarMatch)
                [returnArray addObject:someSong];
        }
    }
    return returnArray;
}

- (UIImage *)squareImageFromImage:(UIImage *)image scaledToSize:(CGFloat)newSize
{
    CGAffineTransform scaleTransform;
    CGPoint origin;
    
    if (image.size.width > image.size.height) {
        CGFloat scaleRatio = newSize / image.size.height;
        scaleTransform = CGAffineTransformMakeScale(scaleRatio, scaleRatio);
        
        origin = CGPointMake(-(image.size.width - image.size.height) / 2.0f, 0);
    } else {
        CGFloat scaleRatio = newSize / image.size.width;
        scaleTransform = CGAffineTransformMakeScale(scaleRatio, scaleRatio);
        
        origin = CGPointMake(0, -(image.size.height - image.size.width) / 2.0f);
    }
    
    CGSize size = CGSizeMake(newSize, newSize);
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextConcatCTM(context, scaleTransform);
    [image drawAtPoint:origin];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (BOOL)isImageAlreadySquare:(UIImage *)image
{
    //calculate how much one length varies from the other.
    int diff = abs((int)image.size.width - (int)image.size.height);
    if(diff > 2)
        //image is not a perfect (or close to perfect) square.
        return NO;
    else
        return YES;
}

@end
