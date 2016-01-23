//
//  DiscogsSearchService.m
//  Sterrio
//
//  Created by Mark Zgaljic on 5/15/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "DiscogsSearchService.h"
#import "DiscogsItem.h"
#import "SDCAlertController.h"

//Requests are throttled by the server to 20 per minute per IP address.
//locally throttling to 1 request per 3 seconds helps abide by the rate limit (3 * 20 = 60).
double const DISCOGS_SECONDS_BETWEEN_REQUESTS = 3;

@interface DiscogsSearchService ()
@property (nonatomic, strong) SMWebRequest *request;
@property (nonatomic, strong) NSDate *lastQueryDate;
@property (nonatomic, assign) id delegate;
@end

@implementation DiscogsSearchService

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (instancetype)queryWithTitle:(NSString *)title callbackDelegate:(id)delegate;
{
    self.delegate = delegate;
    
    [self.request cancel]; // in case one was running already
    self.request = [DiscogsItem requestForDiscogsItems:title];
    [self.request addTarget:self
                     action:@selector(requestComplete:)
           forRequestEvents:SMWebRequestEventComplete];
    [self.request addTarget:self
                     action:@selector(requestError:)
           forRequestEvents:SMWebRequestEventError];
    
    if(self.lastQueryDate == nil) {
        self.lastQueryDate = [NSDate date];
        [self.request start];
    } else {
        NSTimeInterval secondsElapsed = fabs([self.lastQueryDate timeIntervalSinceNow]);
        self.lastQueryDate = [NSDate date];
        
        if(secondsElapsed >= DISCOGS_SECONDS_BETWEEN_REQUESTS) {
            [self.request start];
        } else {
            double remainingRateLimit = DISCOGS_SECONDS_BETWEEN_REQUESTS - secondsElapsed;
            [self.request performSelector:@selector(start) withObject:nil afterDelay:remainingRateLimit];
        }
    }
    
    return self;
}

- (void)cancelAllPendingRequests
{
    [self.request removeTarget:self];
    [self.request cancel];
}

- (void)requestComplete:(NSArray *)theItems
{
    [self.delegate performSelectorOnMainThread:@selector(videoSongSuggestionsRequestComplete:)
                                    withObject:theItems
                                 waitUntilDone:YES];
    self.delegate = nil;
}

- (void)requestError:(NSError *)theError
{
    [self.delegate performSelectorOnMainThread:@selector(videoSongSuggestionsRequestError:)
                                    withObject:theError
                                 waitUntilDone:YES];
    self.delegate = nil;
}

@end
