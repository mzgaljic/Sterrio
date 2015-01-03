//
//  YouTubeVideo.h
//  zTunes
//
//  Created by Mark Zgaljic on 8/1/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YouTubeVideo : NSObject
{
    
}
@property (nonatomic, strong) NSString *videoName;
@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSString *videoThumbnailUrl;  //this is really "medium" quality, not the default.
@property (nonatomic, strong) NSString *videoThumbnailUrlHighQuality;
@property (nonatomic, strong) NSString *channelTitle;

@end