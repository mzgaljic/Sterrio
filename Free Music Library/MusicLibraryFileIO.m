//
//  MusicLibraryFileIO.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/12/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MusicLibraryFileIO.h"
#import "FileIOConstants.h"

@implementation MusicLibraryFileIO

- (BOOL)writeAllLibraryContents
{    
    NSMutableArray *items = [NSMutableArray array];
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:items];
    
    //[items addObject:<#(id)#>];   add objects to be saved
    
    [fileData writeToURL: [[FileIOConstants createSingleton] libraryFileURL] atomically:YES];
    
    return NO;
}

- (BOOL)readAllLibraryContents
{
    NSData *data = [NSData dataWithContentsOfURL:[[FileIOConstants createSingleton] libraryFileURL]];
    NSMutableArray *items = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSLog(@"%@", items);
    return NO;
}

- (NSString *)documentsPathForFileName:(NSString *)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    return [documentsPath stringByAppendingPathComponent:name];
}

@end
