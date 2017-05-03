//
//  DiscogsSearchDelegate.h
//  FMV - Free Music Videos
//
//  Created by Mark Zgaljic on 12/28/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DiscogsSearchDelegate <NSObject>
@optional
- (void)videoSongSuggestionsRequestComplete:(NSArray *)theItems;
- (void)videoSongSuggestionsRequestError:(NSError *)theError;
@end
