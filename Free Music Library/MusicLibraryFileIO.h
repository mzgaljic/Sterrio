//
//  MusicLibraryFileIO.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/12/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MusicLibraryFileIO : NSObject

- (BOOL)writeAllLibraryContents;
- (NSString *)documentsPathForFileName:(NSString *)name;

@end
