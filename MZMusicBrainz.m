//
//  MZMusicBrainz.m
//  Sterrio
//
//  Created by Mark Zgaljic on 5/15/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZMusicBrainz.h"
#import "YouTubeVideo.h"
//#import "SMXMLDocument.h"
#import "SMWebRequest.h"

NSString * const MUSIC_BRAINZ_CLIENT_NAME = @"Sterrio - iOS App";
NSString * const MUSIC_BRAINZ_SERVER_URL = @"musicbrainz.org";
int const MUSIC_BRAINZ_QUERY_LIMIT = 10;

@interface MZMusicBrainz ()
@property (nonatomic, strong) YouTubeVideo *ytVideo;
@property (nonatomic, strong) SMWebRequest *request;
@property (nonatomic, strong) NSArray *items;
@end

@implementation MZMusicBrainz

- (void)dealloc
{
    self.ytVideo = nil;
    self.delegate = nil;
}

- (void)searchMusicBrainzForSongSuggestionsGivenYtVideo:(YouTubeVideo *)ytVideo
{
    [self.request cancel]; // in case one was running already
    //self.request = [RSSItem requestForItemsWithURL:self.feedURL];
}

- (NSURL *)queryUrlForSongtitle:(NSString *)title artist:(NSString *)artistName
{
    return nil;
}


/*
- (void)searchMusicBrainzForSongSuggestionsGivenYtVideo:(YouTubeVideo *)ytVideo
{
    MBConnection *conn = [self connectionForMusicBrainzQuery];
    MBRequest *request = [MBRequest searchForEntity:MBEntityRelease
                                              query:[ytVideo.videoName copy]
                                              limit:[NSNumber numberWithInt:MUSIC_BRAINZ_QUERY_LIMIT]
                                             offset:@0];
    
    __block YouTubeVideo *blockVideo = self.ytVideo;
    __block id<MZMusicBrainzDelegate> blockDelegate = self.delegate;
    void (^successBlock) (MBRequest*, MBMetadata*) = ^(MBRequest * request, MBMetadata * metadata)
    {
        NSArray *suggestions = [MZMusicBrainz songInfoSuggestionsFromResponseMetaData:metadata];
        [blockDelegate songInfoSuggestions:suggestions forYoutubeVideo:blockVideo];
        blockDelegate = nil;
        blockVideo = nil;
    };
    
    void (^failureBlock) (MBRequest*, NSError*, NSData*) = ^(MBRequest * request, NSError * error, NSData * response)
    {
        //lets delegate notify user through GUI that auto-suggestions are unavailable at the moment.
        [blockDelegate failedToFetchSongInfoSuggestionsForYoutubeVideo:blockVideo];
        blockDelegate = nil;
        blockVideo = nil;
    };
    
    [conn enqueueRequest:request
               onSuccess:successBlock
               onFailure:failureBlock];
}

- (MBConnection *)connectionForMusicBrainzQuery
{
    return [MBConnection connectionWithClientName:MUSIC_BRAINZ_CLIENT_NAME
                                           server:MUSIC_BRAINZ_SERVER_URL
                                             port:@80];
}

+ (NSArray *)songInfoSuggestionsFromResponseMetaData:(MBMetadata *)metaData
{
    int numReleases = [metaData.ReleaseList.Count intValue];
    NSMutableArray *suggestions = [NSMutableArray arrayWithCapacity:numReleases];
    for(int i = 0; i < numReleases; i++)
    {
        
    }
    
    return suggestions;
}
*/
@end
