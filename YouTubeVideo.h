//
//  YouTubeVideo.h
//  zTunes
//
//  Created by Mark Zgaljic on 8/1/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YouTubeVideo : NSObject <NSCopying>
@property (nonatomic, strong) NSString *videoName;
@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSString *videoThumbnailUrl;  //this is really "medium" quality in YT apis
@property (nonatomic, strong) NSString *videoThumbnailUrlHighQuality;
@property (nonatomic, strong) NSString *channelTitle;
///Video duration in seconds.
@property (nonatomic, assign) NSUInteger duration;

/**
 *Removes as much garbage from the video title as possible. (ie: "[HQ]", "Lyrics", etc.)
 
 Calling this method multiple times does not incur a noticeable performance penalty,
 the sanitized title is cached.
 */
- (NSString *)sanitizedTitle;

@end
