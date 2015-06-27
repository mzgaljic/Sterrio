//
//  MZMusicBrainz.h
//  Sterrio
//
//  Created by Mark Zgaljic on 5/15/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MZMusicBrainzDelegate.h"

@interface MZMusicBrainz : NSObject

@property (nonatomic, assign) id<MZMusicBrainzDelegate> delegate;

- (void)searchMusicBrainzForSongSuggestionsGivenYtVideo:(YouTubeVideo *)ytVideo;

@end
