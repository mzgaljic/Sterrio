//
//  YouTubeSearchSuggestion.h
//  Sterrio
//
//  Created by Mark Zgaljic on 2/7/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMWebRequest.h"

@interface YouTubeSearchSuggestion : NSObject
@property (nonatomic, strong) NSString *querySuggestion;

+ (SMWebRequest *)requestForYouTubeSearchSuggestions:(NSString *)query;

@end
