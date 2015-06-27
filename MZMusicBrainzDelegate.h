//
//  MZMusicBrainzDelegate.h
//  Sterrio
//
//  Created by Mark Zgaljic on 5/15/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YouTubeVideo;
@protocol MZMusicBrainzDelegate <NSObject>

- (void)songInfoSuggestions:(NSArray *)MZSongInfoSuggestions forYoutubeVideo:(YouTubeVideo *)ytVideo;
- (void)failedToFetchSongInfoSuggestionsForYoutubeVideo:(YouTubeVideo *)ytVideo;

@end
