//
//  FetchVideoInfoOperation.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/21/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"
#import "PlayerView.h"
#import "VideoPlayerWrapper.h"
#import "AppDelegate.h"

@interface FetchVideoInfoOperation : NSOperation

- (id)initWithSongsYoutubeId:(NSString *)youtubeId
                    songName:(NSString *)songName
                  artistName:(NSString *)artistName
             managedObjectId:(NSManagedObjectID *)objId;

/**
 * @return the full video url for the provided videoId, or nil if the operation failed for any reason.
 */
+ (NSURL *)fullVideoUrlFromSterrioServer:(NSString *)videoId maxVideoResolution:(short)maxVideoRes;
+ (short)maxDesiredVideoQualityForConnectionTypeWifi:(BOOL)wifi;
@end
