//
//  YouTubeVideo.h
//  zTunes
//
//  Created by Mark Zgaljic on 8/1/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YouTubeVideo : NSObject
@property (nonatomic, strong) NSString *videoName;
@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSString *videoThumbnailUrl;  //this is really "medium" quality in YT apis
@property (nonatomic, strong) NSString *videoThumbnailUrlHighQuality;
@property (nonatomic, strong) NSString *channelTitle;
@property (nonatomic, assign) BOOL isLivePerformance;
@property (nonatomic, strong) NSArray *featuredArtists;
@property (nonatomic, strong) NSDate *publishDate;
///Video duration in seconds.
@property (nonatomic, assign) NSUInteger duration;

/**
 *Removes as much garbage from the video title as possible. (ie: "[HQ]", "Lyrics", etc.)
 
 Calling this method multiple times will incur decent performance penalty as the title is
 recomputed each time.
 */
- (NSString *)sanitizedTitle;

@end
