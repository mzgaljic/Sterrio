//
//  MusicStoreService.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/26/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ServiceCompletionBlock)(id result, NSError *error);
@interface MusicStoreService : NSObject

-(void)findArtistByArtistName:(NSString*) artistName completionBlock:(ServiceCompletionBlock)completionBlock;

//-(void)loadAlbumsForArtist:(Artist *) artist completionBlock:(ServiceCompletionBlock)completionBlock;

@end
