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

/** 
 * @return an array of NSNumbers, with the underlying numbers being MatchConfidence enum values. The order
 * matches that of the discog item array parameter.
 */
+ (NSArray<NSNumber*> *)getConfidenceLevelsForDiscogsItemResults:(NSArray *)discogsItems
                                                    youtubeVideo:(YouTubeVideo *)ytVideo;
+ (NSUInteger)indexOfBestMatchFromResults:(NSArray *)discogsItems;

/**
 * Performs analysis on a DiscogsItem to generate a clean song name.
 */
+ (NSString *)analyzeAndGenerateCleanedSongNameWithItem:(DiscogsItem *)item
                                           youtubeVideo:(YouTubeVideo *)ytVideo;

/**
 * Performs analysis on a DiscogsItem to generate a clean artist name.
 */
+ (NSString *)analyzeAndGenerateCleanedArtistNameWithItem:(DiscogsItem *)item;

@end
