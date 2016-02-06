//
//  DiscogsSearchUtils.h
//  Sterrio
//
//  Created by Mark Zgaljic on 12/28/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DiscogsItem.h"
#import "YouTubeVideo.h"

@interface DiscogsResultsUtils : NSObject

+ (void)applyConfidenceLevelsToDiscogsItemsForResults:(NSArray **)discogsItems
                                         youtubeVideo:(YouTubeVideo *)ytVideo;
+ (NSUInteger)indexOfBestMatchFromResults:(NSArray *)discogsItems;

+ (void)applySongNameToDiscogsItem:(DiscogsItem **)discogsItem youtubeVideo:(YouTubeVideo *)ytVideo;

+ (void)applyFinalArtistNameLogicForPresentation:(DiscogsItem **)discogsItem;

@end
