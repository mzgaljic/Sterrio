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

@property (nonatomic, strong) NSMutableDictionary *commonDiscogsItems;
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

- (instancetype)init
{
    if(self = [super init]) {
        _commonDiscogsItems = [[NSMutableDictionary alloc] initWithCapacity:100];
        [self initCommonDiscogsItemsDict];
    }
    return self;
}

- (instancetype)queryWithTitle:(NSString *)title
                       videoId:(NSString *)videoId
              callbackDelegate:(id)delegate
{
    DiscogsItem *item = [_commonDiscogsItems objectForKey:videoId];
    if(item) {
        item.matchConfidence = MatchConfidence_HIGH;
        item.itemGuranteedCorrect = YES;
        //looks like this video id was stored in the dict! User can avoid hitting the network.
        [delegate performSelectorOnMainThread:@selector(videoSongSuggestionsRequestComplete:)
                                        withObject:@[item]
                                     waitUntilDone:NO];
        return self;
    }
    
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

#pragma mark - Avoiding network requests for extremely popular or hard to match videos
- (void)initCommonDiscogsItemsDict
{
    NSArray *letItGoIdinaIds = @[@"moSFlvxnbgk", @"L0MK7qz13bU"];
    NSArray *letItGoDemiIds = @[@"kHue-HaXXzg"];
    NSArray *frozenHeartIds = @[@"g4wLEoakY7M", @"9MPGyx7N1XI", @"TISp0swKhkk", @"1udIKnemaW8",
                                @"1TXc2JbCjmw"];
    NSArray *wantToBuildASnowmanIds = @[@"V-zXT5bIBM0", @"zrPm3SrXPyk", @"9YwXff-i1fY", @"tsUw1Oc4P54",
                                     @"hds7Ny6v6NY"];
    NSArray *forFirstTimeInForeverIds = @[@"EgMN0Cfh-aQ", @"dOReid0vEwY", @"nVm2e9zJB_M",
                                          @"_UA3xY0OxI4", @"wmoR82v6G5o"];
    NSArray *loveIsAnOpenDoorIds = @[@"nPImqZo0D74", @"j6nnoWgbdvg", @"n5T_QgyGse0"];
    NSArray *reindeersAreBetterThanPeopleIds = @[@"W-oFqCVNnbM", @"caYlllBWLaw", @"w6QaIDHYIiA"];
    NSArray *inSummerIds = @[@"UFatVn1hP3o", @"B2jeR_OpOGE", @"_axMza-fR3Q"];
    NSArray *fixerUpperIds = @[@"6FJyMwYB2yw", @"IHUvALTEDJQ", @"GOGKltmWYTM", @"lWtTdRmSrYQ"];
    NSArray *vuelieIds = @[@"iKL4zBxFygw"];
    NSArray *elsaAndAnnaIds = @[@"Qo2uvrvdiAY"];
    NSArray *theTrollsIds = @[@"N6zegb5f1w8"];
    NSArray *coronationDayIds = @[@"AfmXTlI14BA"];
    NSArray *somePeopleAreWorthMeltingForIds = @[@"our5ioN26YY"];
    
    NSString *frozenAlbumName = @"Frozen (Deluxe Edition)";
    DiscogsItem *letItGoIdina = [[DiscogsItem alloc] init];
    letItGoIdina.songName = @"Let it Go";
    letItGoIdina.albumName = frozenAlbumName;
    letItGoIdina.artistName = @"Idina Menzel";
    DiscogsItem *letItGoDemi = [[DiscogsItem alloc] init];
    letItGoDemi.songName = @"Let it Go (Single Version)";
    letItGoDemi.albumName = frozenAlbumName;
    letItGoDemi.artistName = @"Demi Lovato";
    DiscogsItem *frozenHeart = [[DiscogsItem alloc] init];
    frozenHeart.songName = @"Frozn Heart";
    frozenHeart.albumName = frozenAlbumName;
    frozenHeart.artistName = @"Frozen - Various";
    DiscogsItem *wantToBuildASnowman = [[DiscogsItem alloc] init];
    wantToBuildASnowman.songName = @"Do You Want to Build a Snowman?";
    wantToBuildASnowman.albumName = frozenAlbumName;
    wantToBuildASnowman.artistName = @"Kristen Bell";
    DiscogsItem *forFirstTimeInForever = [[DiscogsItem alloc] init];
    forFirstTimeInForever.songName = @"For the First in Forever (Reprise)";
    forFirstTimeInForever.albumName = frozenAlbumName;
    forFirstTimeInForever.artistName = @"Kristen Bell & Indina Menzel";
    DiscogsItem *loveIsAnOpenDoor = [[DiscogsItem alloc] init];
    loveIsAnOpenDoor.songName = @"Love Is an Open Door";
    loveIsAnOpenDoor.albumName = frozenAlbumName;
    loveIsAnOpenDoor.artistName = @"Frozen - Various";
    DiscogsItem *reindeersAreBetterThanPeople = [[DiscogsItem alloc] init];
    reindeersAreBetterThanPeople.songName = @"Reindeer(s) Are Better Than People";
    reindeersAreBetterThanPeople.albumName = frozenAlbumName;
    reindeersAreBetterThanPeople.artistName = @"Jonathan Groff";
    DiscogsItem *inSummer = [[DiscogsItem alloc] init];
    inSummer.songName = @"In Summer";
    inSummer.albumName = frozenAlbumName;
    inSummer.artistName = @"Josh Gad";
    DiscogsItem *fixerUpper = [[DiscogsItem alloc] init];
    fixerUpper.songName = @"Fixer Upper";
    fixerUpper.albumName = frozenAlbumName;
    fixerUpper.artistName = @"Frozen - Various";
    DiscogsItem *vuelie = [[DiscogsItem alloc] init];
    vuelie.songName = @"Vuelie (feat. Cantus)";
    vuelie.albumName = frozenAlbumName;
    vuelie.artistName = @"Frozen - Various";
    DiscogsItem *elsaAndAnna = [[DiscogsItem alloc] init];
    elsaAndAnna.songName = @"Elsa and Anna";
    elsaAndAnna.albumName = frozenAlbumName;
    elsaAndAnna.artistName = @"Christophe Beck";
    DiscogsItem *theTrolls = [[DiscogsItem alloc] init];
    theTrolls.songName = @"The Trolls";
    theTrolls.albumName = frozenAlbumName;
    theTrolls.artistName = @"Christophe Beck";
    DiscogsItem *coronationDay = [[DiscogsItem alloc] init];
    coronationDay.songName = @"Coronation Day";
    coronationDay.albumName = frozenAlbumName;
    coronationDay.artistName = @"Christophe Beck";
    DiscogsItem *somePeopleAreWorthMeltingFor = [[DiscogsItem alloc] init];
    somePeopleAreWorthMeltingFor.songName = @"Some People Are Worth Melting For";
    somePeopleAreWorthMeltingFor.albumName = frozenAlbumName;
    somePeopleAreWorthMeltingFor.artistName = @"Christophe Beck";
    
    for(NSString *anId in letItGoIdinaIds) {
        [_commonDiscogsItems setObject:letItGoIdina forKey:anId];
    }
    for(NSString *anId in letItGoDemiIds) {
        [_commonDiscogsItems setObject:letItGoDemi forKey:anId];
    }
    for(NSString *anId in frozenHeartIds) {
        [_commonDiscogsItems setObject:frozenHeart forKey:anId];
    }
    for(NSString *anId in wantToBuildASnowmanIds) {
        [_commonDiscogsItems setObject:wantToBuildASnowman forKey:anId];
    }
    for(NSString *anId in forFirstTimeInForeverIds) {
        [_commonDiscogsItems setObject:forFirstTimeInForever forKey:anId];
    }
    for(NSString *anId in loveIsAnOpenDoorIds) {
        [_commonDiscogsItems setObject:loveIsAnOpenDoor forKey:anId];
    }
    for(NSString *anId in reindeersAreBetterThanPeopleIds) {
        [_commonDiscogsItems setObject:reindeersAreBetterThanPeople forKey:anId];
    }
    for(NSString *anId in inSummerIds) {
        [_commonDiscogsItems setObject:inSummer forKey:anId];
    }
    for(NSString *anId in fixerUpperIds) {
        [_commonDiscogsItems setObject:fixerUpper forKey:anId];
    }
    for(NSString *anId in vuelieIds) {
        [_commonDiscogsItems setObject:vuelie forKey:anId];
    }
    for(NSString *anId in elsaAndAnnaIds) {
        [_commonDiscogsItems setObject:elsaAndAnna forKey:anId];
    }
    for(NSString *anId in theTrollsIds) {
        [_commonDiscogsItems setObject:theTrolls forKey:anId];
    }
    for(NSString *anId in coronationDayIds) {
        [_commonDiscogsItems setObject:coronationDay forKey:anId];
    }
    for(NSString *anId in somePeopleAreWorthMeltingForIds) {
        [_commonDiscogsItems setObject:somePeopleAreWorthMeltingFor forKey:anId];
    }
}

@end
