//
//  DiscogsSearchService.m
//  Sterrio
//
//  Created by Mark Zgaljic on 5/15/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "DiscogsSearchService.h"
#import "YouTubeVideo.h"
#import "DiscogsItem.h"
#import "SMWebRequest.h"
#import "SDCAlertController.h"

NSString * const MUSIC_BRAINZ_CLIENT_NAME = @"Sterrio - iOS App";
NSString * const MUSIC_BRAINZ_SERVER_URL = @"musicbrainz.org";
int const MUSIC_BRAINZ_QUERY_LIMIT = 10;

@interface DiscogsSearchService ()
@property (nonatomic, strong) YouTubeVideo *ytVideo;
@property (nonatomic, strong) SMWebRequest *request;
@property (nonatomic, strong) NSArray *items;
@end

@implementation DiscogsSearchService

- (void)dealloc
{
    self.ytVideo = nil;
}

- (id)initAndQueryWithTitle:(NSString *)title
{
    if(self = [super init]) {
        [self queryWithTitle:title];
    }
    return self;
}

- (void)queryWithTitle:(NSString *)title;
{
    [self.request cancel]; // in case one was running already
    self.request = [DiscogsItem requestForDiscogsItems:title];
    [self.request addTarget:self
                     action:@selector(requestComplete:)
           forRequestEvents:SMWebRequestEventComplete];
    [self.request addTarget:self
                     action:@selector(requestError:)
           forRequestEvents:SMWebRequestEventError];
    [self.request start];
}

- (void)requestComplete:(NSArray *)theItems
{
    NSLog(@"request done yo!");
    
    NSString *msg = nil;
    if(theItems.count > 0) {
        DiscogsItem *item = theItems[0];
        msg = [NSString stringWithFormat:@"Artist: %@\n\nAlbum: %@", item.artistName, item.albumName];
    } else {
        msg = @"No suggestions found.";
    }
    
    SDCAlertController *alert =[SDCAlertController alertControllerWithTitle:@"Song Metadata suggestions"
                                                                    message:msg
                                                             preferredStyle:SDCAlertControllerStyleAlert];
    SDCAlertAction *act = [SDCAlertAction actionWithTitle:@"Okay"
                                                    style:SDCAlertActionStyleRecommended
                                                  handler:nil];
    [alert addAction:act];
    [alert presentWithCompletion:nil];
}

- (void)requestError:(NSError *)theError
{
     NSLog(@"request failed :(");
}

@end
