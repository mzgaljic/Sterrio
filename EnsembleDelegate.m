//
//  EnsembleDelegate.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/2/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "EnsembleDelegate.h"
#import "CoreDataManager.h"
#import "AlbumAlbumArt.h"
#import "SongAlbumArt.h"
#import "AppEnvironmentConstants.h"
#import "MRProgress.h"
#import "SpotlightHelper.h"
#import "PlayableItem.h"
#import "MusicPlaybackController.h"
#import "MyAlerts.h"

@implementation EnsembleDelegate
static MRProgressOverlayView *hud;

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
    if(self = [super init]){
        NSString *newFilesToMergeNotif = CDEICloudFileSystemDidDownloadFilesNotification;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(ensemblesHasDownloadedFilesToMerge)
                                                     name:newFilesToMergeNotif
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    //shouldnt ever be called, but whatever lol.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)ensemblesHasDownloadedFilesToMerge
{
    CDEPersistentStoreEnsemble *ensemble = [[CoreDataManager sharedInstance] ensembleForMainContext];
    [ensemble mergeWithCompletion:^(NSError *error) {
        if(error){
            NSLog(@"Files were just downloaded, but merge failed.");
        } else{
            NSLog(@"Files just downloaded and merged.");
            [AppEnvironmentConstants setLastSuccessfulSyncDate:[[NSDate alloc] init]];
        }
    }];
}

//METHOD INVOKED ON BACKGROUND THREAD
- (void)persistentStoreEnsemble:(CDEPersistentStoreEnsemble *)ensemble didSaveMergeChangesWithNotification:(NSNotification *)notification
{
    NSManagedObjectContext *context = [CoreDataManager context];
    [context performBlock:^{
        [context mergeChangesFromContextDidSaveNotification:notification];
    }];
    
    NSManagedObjectContext *stackControllerThreadContext = [CoreDataManager stackControllerThreadContext];
    [stackControllerThreadContext performBlock:^{
        [stackControllerThreadContext mergeChangesFromContextDidSaveNotification:notification];
    }];
    
    NSManagedObjectContext *backgroundManagedObjectContext = [CoreDataManager backgroundThreadContext];
    [backgroundManagedObjectContext performBlock:^{
        [backgroundManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    }];
}

//METHOD INVOKED ON BACKGROUND THREAD
- (BOOL)persistentStoreEnsemble:(CDEPersistentStoreEnsemble*)ensemble shouldSaveMergedChangesInManagedObjectContext:(NSManagedObjectContext *)savingContext reparationManagedObjectContext:(NSManagedObjectContext *)reparationContext
{
    if([AppEnvironmentConstants isABadTimeToMergeEnsemble])
        return NO;
    else{
        //update the spotlight index with changes in the library, AND add songs to LQ Art updater.
        __block BOOL nowPlayingDeleted = NO;
        [savingContext performBlockAndWait:^{
            NSSet *setOfDeletedObjects = [savingContext deletedObjects];
            NSSet *setOfInsertedObjects = [savingContext insertedObjects];
            NSSet *setOfUpdatedObjects = [savingContext updatedObjects];
            __block NSUInteger objsIterated = 0;
            NSUInteger totalObjCount = setOfDeletedObjects.count
                                    + setOfInsertedObjects.count
                                    + setOfUpdatedObjects.count;
            
            if(totalObjCount > 100){  //only show gui alert if it will take a reasonably long time...
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [EnsembleDelegate startTimingExecution];
                    //shows progress bar (its updated below)
                    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
                    hud = [MRProgressOverlayView showOverlayAddedTo:keyWindow
                                                              title:@"Spotlight is indexing your music."
                                                               mode:MRProgressOverlayViewModeDeterminateHorizontalBar
                                                           animated:YES];
                });
            }
            
            [setOfDeletedObjects enumerateObjectsUsingBlock:^(id  __nonnull obj, BOOL * __nonnull stop) {
                if([obj isMemberOfClass:[Song class]]){
                    PlayableItem *currSong = [NowPlaying sharedInstance].nowPlayingItem;
                    if([currSong isEqualToSong:(Song *)obj withContext:currSong.contextForItem]){
                        nowPlayingDeleted = YES;
                    }
                    [SpotlightHelper removeSongFromSpotlightIndex:(Song *)obj];
                } else if([obj isMemberOfClass:[Artist class]]){
                    [SpotlightHelper removeArtistSongsFromSpotlightIndex:(Artist *)obj];
                } else if([obj isMemberOfClass:[Album class]]){
                    [SpotlightHelper removeAlbumSongsFromSpotlightIndex:(Album *)obj];
                }
                
                [self setHudProgressTo:(float)++objsIterated / (float)totalObjCount];
            }];
            
            [setOfInsertedObjects enumerateObjectsUsingBlock:^(id  __nonnull obj, BOOL * __nonnull stop) {
                //SpotlightHelper API only supports adding songs, but supports removing all 3 music types.
                //this is by design...
                if([obj isMemberOfClass:[Song class]]){
                    Song *aSong = (Song*)obj;
                    if([aSong.nonDefaultArtSpecified boolValue] == NO) {
                        [LQAlbumArtBackgroundUpdater downloadHqAlbumArtWhenConvenientForSongId:aSong.uniqueId];
                    }
                    [SpotlightHelper addSongToSpotlightIndex:(Song *)obj];
                }
                [self setHudProgressTo:(float)++objsIterated / (float)totalObjCount];
            }];
            
            [setOfUpdatedObjects enumerateObjectsUsingBlock:^(id  __nonnull obj, BOOL * __nonnull stop) {
                //stuff
                if([obj isMemberOfClass:[Song class]]){
                    [SpotlightHelper updateSpotlightIndexForSong:(Song *)obj];
                } else if([obj isMemberOfClass:[Artist class]]){
                    [SpotlightHelper updateSpotlightIndexForArtist:(Artist *)obj];
                } else if([obj isMemberOfClass:[Album class]]){
                    [SpotlightHelper updateSpotlightIndexForAlbum:(Album *)obj];
                }
                [self setHudProgressTo:(float)++objsIterated / (float)totalObjCount];
            }];
        }];
        
        if(nowPlayingDeleted){
            [MusicPlaybackController skipToNextTrack];
            [MyAlerts displayAlertWithAlertType:ALERT_TYPE_NowPlayingSongWasDeletedOnOtherDevice];
        }
        
        return YES;
    }
}

//METHOD INVOKED ON BACKGROUND THREAD
- (NSArray *)persistentStoreEnsemble:(CDEPersistentStoreEnsemble *)ensemble
  globalIdentifiersForManagedObjects:(NSArray *)objects
{
    NSMutableArray *arrayOfIds = [NSMutableArray array];
    [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [arrayOfIds addObject:[EnsembleDelegate globalIdentifierForObject:obj]];
    }];
    return arrayOfIds;
}

+ (id)globalIdentifierForObject:(id)someObject
{
    if([someObject respondsToSelector:@selector(uniqueId)]){
        return [someObject performSelector:@selector(uniqueId)];
    } else
        return [NSNull null];
}

#pragma mark - GUI stuff
- (void)setHudProgressTo:(float)value
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        hud.progress = value;
        
        if(value == 1) {
            //at 100%
            NSUInteger minDesiredDuration = 2.4;
            NSTimeInterval time = [EnsembleDelegate timeOnExecutionTimer];
            
            //ensure the hud doesn't dissapear instantly, which would look really bad.
            if(time < minDesiredDuration){
                [NSThread sleepForTimeInterval:fabs(time - minDesiredDuration)];
            }
            
            [hud dismiss:YES];
            hud = nil;
        }
    });
}

static NSDate *start;
static NSDate *finish;
+ (void)startTimingExecution
{
    start = [NSDate date];
}

+ (NSTimeInterval)timeOnExecutionTimer
{
    if(start == nil)
        return 0;
    finish = [NSDate date];
    NSTimeInterval executionTime = [finish timeIntervalSinceDate:start];
    start = nil;
    finish = nil;
    
    return executionTime;
}

@end
