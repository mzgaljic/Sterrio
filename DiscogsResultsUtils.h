//
//  DiscogsSearchUtils.h
//  Sterrio
//
//  Created by Mark Zgaljic on 12/28/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DiscogsItem.h"

@interface DiscogsResultsUtils : NSObject

/**
 *This method mutates the array passed in (it updates the confidence of eash item).
 */
+ (NSUInteger)indexOfBestMatchFromResults:(NSArray **)discogsItems
                             youtubeVideo:(YouTubeVideo *)ytVideo;

+ (NSString *)songNameForDiscogsItem:(DiscogsItem *)discogsItem youtubeVideo:(YouTubeVideo *)ytVideo;

@end
