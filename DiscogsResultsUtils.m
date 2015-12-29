//
//  DiscogsSearchUtils.m
//  Sterrio
//
//  Created by Mark Zgaljic on 12/28/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import "DiscogsResultsUtils.h"
#import "YouTubeVideo.h"
#import "LevenshteinDistanceItem.h"
#import "NSString+Levenshtein_Distance.h"

@implementation DiscogsResultsUtils

+ (NSUInteger)indexOfBestMatchFromResults:(NSArray **)discogsItems youtubeVideo:(YouTubeVideo *)ytVideo
{
    NSUInteger firstHighConfidenceIndex = NSNotFound;
    NSUInteger firstMediumConfidenceIndex = NSNotFound;
    
    NSString *videoTitle = ytVideo.videoName;
    for(NSUInteger i = 0; i < (*discogsItems).count; i++) {
        DiscogsItem *item = (*discogsItems)[i];
        BOOL albumNameInTitle = ([videoTitle rangeOfString:item.albumName].location != NSNotFound);
        BOOL artistNameInTitle = ([videoTitle rangeOfString:item.artistName].location != NSNotFound);

        if (albumNameInTitle && artistNameInTitle) {
            item.matchConfidence = MatchConfidence_HIGH;
            firstHighConfidenceIndex = i;
        } else if(albumNameInTitle || artistNameInTitle){
            item.matchConfidence = MatchConfidence_MEDIUM;
            firstMediumConfidenceIndex = i;
        } else {
            item.matchConfidence = MatchConfidence_LOW;
        }
    }

    return (firstHighConfidenceIndex == NSNotFound) ?   firstMediumConfidenceIndex
                                                        :
                                                        firstHighConfidenceIndex;
}

+ (NSString *)songNameForDiscogsItem:(DiscogsItem *)discogsItem youtubeVideo:(YouTubeVideo *)ytVideo
{
    
}

@end
