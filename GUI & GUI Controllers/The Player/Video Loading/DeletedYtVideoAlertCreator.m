//
//  YTVideoAvailabilityChecker.m
//  Sterrio
//
//  Created by Mark Zgaljic on 2/24/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "DeletedYtVideoAlertCreator.h"
#import "ReachabilitySingleton.h"
#import "YouTubeService.h"
#import "SDCAlertControllerView.h"
#import "YoutubeResultsTableViewController.h"

@implementation DeletedYtVideoAlertCreator

+ (void)createVideoDeletedAlertWithYtVideoId:(NSString *)videoId
                                        name:(NSString *)name
                                  artistName:(NSString *)artistName
                             managedObjectId:(NSManagedObjectID *)objId
{
    if([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        [MusicPlaybackController skipToNextTrack];
    }
    SDCAlertAction *okAction = [SDCAlertAction actionWithTitle:@"OK"
                                                         style:SDCAlertActionStyleDefault
                                                       handler:^(SDCAlertAction *action) {
                                                           if([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                                                               [MusicPlaybackController skipToNextTrack];
                                                           }
                                                       }];
    NSString *ytQuery = [DeletedYtVideoAlertCreator queryStringForSongWithName:name
                                                               artistName:artistName];
    SDCAlertAction *findNewAction = [SDCAlertAction actionWithTitle:@"Find new video"
                                                              style:SDCAlertActionStyleRecommended
                                                            handler:[self findNewActionHandlerWithQuery:ytQuery objId:objId]];
    [MyAlerts displayVideoNoLongerAvailableOnYtAlertForSong:name
                                              customActions:@[okAction, findNewAction]];
}

+ (void (^)(SDCAlertAction *))findNewActionHandlerWithQuery:(NSString *)query
                                                      objId:(NSManagedObjectID *)objectId
{
    __block NSString *weakQuery = query;
    return ^(SDCAlertAction *action) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            YoutubeResultsTableViewController *ytResultsVc;
            ytResultsVc = [YoutubeResultsTableViewController initWithSearchQuery:weakQuery
                                                                replacementObjId:objectId];
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
