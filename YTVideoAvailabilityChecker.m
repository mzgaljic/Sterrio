//
//  YTVideoAvailabilityChecker.m
//  Sterrio
//
//  Created by Mark Zgaljic on 2/24/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "YTVideoAvailabilityChecker.h"
#import "ReachabilitySingleton.h"
#import "YouTubeService.h"
#import "SDCAlertControllerView.h"
#import "YoutubeResultsTableViewController.h"

@implementation YTVideoAvailabilityChecker

/*
 * Blocks the caller.
 */
+ (BOOL)warnUserIfVideoNoLongerExistsForSongWithId:(NSString *)videoId
                                              name:(NSString *)name
                                        artistName:(NSString *)artistName
{
    if(videoId == nil
       || name == nil
       || [[ReachabilitySingleton sharedInstance] isConnectionCompletelyGone]) {
        return YES;
    }
    
    BOOL exists = [YouTubeService doesVideoStillExist:videoId];
    if(! exists) {
        SDCAlertAction *okAction = [SDCAlertAction actionWithTitle:@"OK"
                                                             style:SDCAlertActionStyleDefault
                                                           handler:nil];
        NSString *ytQuery = [YTVideoAvailabilityChecker queryStringForSongWithName:name
                                                                        artistName:artistName];
        SDCAlertAction *findNewAction = [SDCAlertAction actionWithTitle:@"Find new video"
                                                                  style:SDCAlertActionStyleRecommended
                                                                handler:[self findNewActionHandlerWithQuery:ytQuery]];
        [MyAlerts displayVideoNoLongerAvailableOnYtAlertForSong:name
                                                  customActions:@[okAction, findNewAction]];
    }
    return exists;
}

+ (void (^)(SDCAlertAction *))findNewActionHandlerWithQuery:(NSString *)query
{
    __block NSString *weakQuery = query;
    return ^(SDCAlertAction *action) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            YoutubeResultsTableViewController *ytResultsVc;
            ytResultsVc = [YoutubeResultsTableViewController initWithSearchQuery:weakQuery];
            UINavigationController *wrappingNavVc;
            wrappingNavVc = [[UINavigationController alloc] initWithRootViewController:ytResultsVc];
            UIWindow *appWindow = [[[UIApplication sharedApplication] delegate] window];
            [appWindow.rootViewController presentViewController:wrappingNavVc
                                                       animated:YES
                                                     completion:nil];
        }];
    };
}

//Assumes songName is NOT nil.
+ (NSString *)queryStringForSongWithName:(NSString *)songName
                              artistName:(NSString *)artistName
{
    return (artistName == nil) ? songName : [NSString stringWithFormat:@"%@ %@", songName, artistName];
}

@end
