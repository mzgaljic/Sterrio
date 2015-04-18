//
//  LQAlbumArtBackgroundUpdater.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/18/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "LQAlbumArtBackgroundUpdater.h"
#import "ReachabilitySingleton.h"
#import "AlbumArtUtilities.h"
#import "LQAlbumArtItem.h"
#import "CoreDataManager.h"
#import "pthread.h"

@interface LQAlbumArtBackgroundUpdater ()
{
    ReachabilitySingleton *reachability;
}
@end
@implementation LQAlbumArtBackgroundUpdater
static LQAlbumArtBackgroundUpdater *internalSingleton;
static NSLock *myLock1;
static BOOL isAsyncUpdateInProgress = NO;

static NSLock *myLock2;
static BOOL abortAsyncArtUpdate = NO;

+ (void)setAsyncUpdateInProgress:(BOOL)inProgress
{
    [myLock1 lock];
    isAsyncUpdateInProgress = inProgress;
    [myLock1 unlock];
}

+ (BOOL)isAsyncUpdateInProgress
{
    BOOL var;
    [myLock1 lock];
    var = isAsyncUpdateInProgress;
    [myLock1 unlock];
    return var;
}


+ (void)setAbortAsyncArtUpdate:(BOOL)abort
{
    [myLock1 lock];
    abortAsyncArtUpdate = abort;
    [myLock1 unlock];
}

+ (BOOL)shouldAbortAsyncArtUpdate
{
    BOOL var;
    [myLock1 lock];
    var = abortAsyncArtUpdate;
    [myLock1 unlock];
    return var;
}

//Public stuff ---------
+ (void)beginWaitingForEfficientMomentsToUpdateAlbumArt
{
    internalSingleton = [LQAlbumArtBackgroundUpdater sharedInstance];
}

+ (void)forceCheckIfItsAnEfficientTimeToUpdateAlbumArt
{
    [internalSingleton connectionStateChanged];
}

+ (void)downloadHqAlbumArtWhenConvenientForSongId:(NSString *)songId;
{
    //add song id to LQAlbumArtItem obj, and place in array, save with NSCoder...
    NSMutableSet *setOfLqAlbumArtItems;
    NSString *archivePath = [AlbumArtUtilities pathToLqAlbumArtNSCodedFile];
    setOfLqAlbumArtItems = [NSKeyedUnarchiver unarchiveObjectWithFile:archivePath];
    if(setOfLqAlbumArtItems == nil)
        setOfLqAlbumArtItems = [NSMutableSet set];
    LQAlbumArtItem *albumArtItem = [[LQAlbumArtItem alloc] init];
    albumArtItem.songId = songId;
    [setOfLqAlbumArtItems addObject:albumArtItem];
    [NSKeyedArchiver archiveRootObject:setOfLqAlbumArtItems toFile:archivePath];
}

//-------------------------

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Object LifeCycle
- (instancetype)init
{
    if(self = [super init]){
        if(reachability == nil)
            reachability = [ReachabilitySingleton sharedInstance];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(connectionStateChanged)
                                                     name:MZReachabilityStateChanged
                                                   object:nil];
    }
    return self;
}

//technically wont ever be called, but whatever...
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - responding to current connection state
- (void)connectionStateChanged
{
    if([reachability isConnectedToInternet])
    {
        if([reachability isConnectedToWifi])
        {
            [LQAlbumArtBackgroundUpdater setAbortAsyncArtUpdate:NO];
            [self startUpdatingOldArtAsyncWrapper];
        }
        else
        {
            [LQAlbumArtBackgroundUpdater setAbortAsyncArtUpdate:YES];
        }
    }
    else
    {
        [LQAlbumArtBackgroundUpdater setAbortAsyncArtUpdate:YES];
    }
}

- (void)startUpdatingOldArtAsyncWrapper
{
    if([LQAlbumArtBackgroundUpdater isAsyncUpdateInProgress])
        return;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MZStartBackgroundTaskHandlerIfInactive
                                                        object:nil];
    __weak LQAlbumArtBackgroundUpdater *weakself = self;
    [LQAlbumArtBackgroundUpdater setAsyncUpdateInProgress:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        pthread_setname_np("MZMusic: LQ Art Updater");
        [weakself startUpdatingLowQualityAlbumArtInBackground];
        [LQAlbumArtBackgroundUpdater setAsyncUpdateInProgress:NO];
    });
}

//thread is called off the main thread
- (void)startUpdatingLowQualityAlbumArtInBackground
{
    NSMutableSet *setOfLqAlbumArtItems;
    NSString *archivePath = [AlbumArtUtilities pathToLqAlbumArtNSCodedFile];
    setOfLqAlbumArtItems = [NSKeyedUnarchiver unarchiveObjectWithFile:archivePath];
    
    //no work to do. Yay!
    if(setOfLqAlbumArtItems == nil || setOfLqAlbumArtItems.count == 0)
        return;
    
    NSMutableArray *itemsToDelete = [NSMutableArray array];
    int counter = 0;
    for(LQAlbumArtItem *lqItem in setOfLqAlbumArtItems)
    {
        if([LQAlbumArtBackgroundUpdater shouldAbortAsyncArtUpdate])
            break;
        
        Song *itemSong = [self songObjectGivenSongId:lqItem.songId];
        BOOL songStillExists = (itemSong != nil);
        
        NSString *albumArtNameOnDisk = [self getAlbumArtNameForSong:itemSong];
        BOOL downloadedHqArtSuccessfully = NO;
        
        if(songStillExists && albumArtNameOnDisk)
        {
            NSData *data;
            NSArray *hqThumbnailUrls = [self highQualityThumbnailUrlsForYoutubeVideoId:lqItem.songId];
            for(int i = 0; i < hqThumbnailUrls.count; i++)
            {
                NSURL *url = [NSURL URLWithString:hqThumbnailUrls[i]];
                data = [NSData dataWithContentsOfURL:url];
                
                if(data != nil && data.length != 0){
                    downloadedHqArtSuccessfully = YES;
                    break;
                }
            }
            
            if(downloadedHqArtSuccessfully)
            {
                UIImage *hqArt = [[UIImage alloc] initWithData:data];
                //will overwrite the existing file
                albumArtNameOnDisk = [self addImageJpgExtensionIfNotPresent:albumArtNameOnDisk];
                [AlbumArtUtilities saveAlbumArtFileWithName:albumArtNameOnDisk andImage:hqArt];
                counter++;
            }
        }
        
        if(downloadedHqArtSuccessfully || songStillExists == NO)
            [itemsToDelete addObject:lqItem];
    }
    
    //fetch set from disk again before we modify it, since the user could have
    //saved a new song which needs an album art change while we were going through
    //this loop. Yes, this is NOT thread safe in theory, but in practice it is "good enough" here.
    setOfLqAlbumArtItems = [NSKeyedUnarchiver unarchiveObjectWithFile:archivePath];
    
    //delete items/tasks which were accomplished
    for(LQAlbumArtItem *someItem in itemsToDelete){
        [setOfLqAlbumArtItems removeObject:someItem];
    }
    
    //save the array to disk (in case all of the tasks couldn't complete)
    [NSKeyedArchiver archiveRootObject:setOfLqAlbumArtItems toFile:archivePath];
    NSLog(@"Updated %i LQ ALbum Art", counter);
}

- (NSArray *)highQualityThumbnailUrlsForYoutubeVideoId:(NSString *)videoId
{
    NSString *maxResDefault, *sdDefault, *hqDefault;  //1920x1080, 640x480, and 480x360 (respectively)

    maxResDefault = [NSString stringWithFormat:@"http://i1.ytimg.com/vi/%@/maxresdefault.jpg", videoId];
    sdDefault = [NSString stringWithFormat:@"http://i1.ytimg.com/vi/%@/sddefault.jpg", videoId];
    hqDefault = [NSString stringWithFormat:@"http://img.youtube.com/vi/%@/hqdefault.jpg", videoId];
    
    //Highest quality urls are first in array
    return @[maxResDefault, sdDefault, hqDefault];
}


- (NSString *)getAlbumArtNameForSong:(Song *)aSong
{
    NSString *artFileName = [NSString stringWithFormat:@"%@.jpg", aSong.song_id];
    BOOL isOnDisk = [AlbumArtUtilities isAlbumArtAlreadySavedOnDisk:artFileName];
    if(isOnDisk && aSong != nil)
        return artFileName;
    else
    {
        if(aSong){
            //check if this album art is still saved under the songs id. if not,
            //figure out what its current name is (ie: its under an album name now).
            if(aSong.album != nil)
                return aSong.album.albumArtFileName;
        }
        return nil;
    }
}

- (Song *)songObjectGivenSongId:(NSString *)songId
{
    if(songId == nil)
        return nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Song"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"song_id == %@", songId];
    //descriptor doesnt really matter here
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"songName"
                                                                     ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    NSArray *results = [[CoreDataManager backgroundThreadContext] executeFetchRequest:fetchRequest error:nil];
    if(results.count == 1)
        return results[0];
    else
        return nil;
}

- (NSString *)addImageJpgExtensionIfNotPresent:(NSString *)fileName
{
    if(fileName){
        //make sure file name has .jpg at the end
        NSString *lastThreeChars = [fileName substringFromIndex: [fileName length] - 4];
        if(! [lastThreeChars isEqualToString:@".jpg"])
            return [NSString stringWithFormat:@"%@.jpg", fileName];
        else
            return fileName;
    }
    else
        return nil;
}


@end
