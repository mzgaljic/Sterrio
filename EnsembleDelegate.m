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
    
    [MRProgressOverlayView dismissAllOverlaysForView:[UIApplication sharedApplication].keyWindow
                                            animated:YES];
}

//METHOD INVOKED ON BACKGROUND THREAD
- (BOOL)persistentStoreEnsemble:(CDEPersistentStoreEnsemble*)ensemble shouldSaveMergedChangesInManagedObjectContext:(NSManagedObjectContext *)savingContext reparationManagedObjectContext:(NSManagedObjectContext *)reparationContext
{
    if([AppEnvironmentConstants isABadTimeToMergeEnsemble])
        return NO;
    else{
        if(! [AppEnvironmentConstants isUserOniOS9OrAbove])  //spotlight can't even be used lol.
            return YES;
        
        //update the spotlight index with changes in the library.
        __block BOOL nowPlayingDeleted = NO;
        [savingContext performBlock:^{
            NSSet *setOfDeletedObjects = [savingContext deletedObjects];
            
            [setOfDeletedObjects enumerateObjectsUsingBlock:^(id  __nonnull obj, BOOL * __nonnull stop) {
                if([obj isMemberOfClass:[Song class]]){
                    PlayableItem *currSong = [NowPlayingSong sharedInstance].nowPlayingItem;
                    if([currSong isEqualToSong:(Song *)obj withContext:currSong.contextForItem]){
                        nowPlayingDeleted = YES;
                    }
                    [SpotlightHelper removeSongFromSpotlightIndex:(Song *)obj];
                } else if([obj isMemberOfClass:[Artist class]]){
                    [SpotlightHelper removeArtistSongsFromSpotlightIndex:(Artist *)obj];
                } else if([obj isMemberOfClass:[Album class]]){
                    [SpotlightHelper removeAlbumSongsFromSpotlightIndex:(Album *)obj];
                }
            }];
            
            NSSet *setOfInsertedObjects = [savingContext insertedObjects];
            [setOfInsertedObjects enumerateObjectsUsingBlock:^(id  __nonnull obj, BOOL * __nonnull stop) {
                //SpotlightHelper API only supports adding songs, but supports removing all 3 music types.
                //this is by design...
                if([obj isMemberOfClass:[Song class]]){
                    [SpotlightHelper addSongToSpotlightIndex:(Song *)obj];
                }
            }];
            
            NSSet *setOfUpdatedObjects = [savingContext updatedObjects];
            [setOfUpdatedObjects enumerateObjectsUsingBlock:^(id  __nonnull obj, BOOL * __nonnull stop) {
                //stuff
                if([obj isMemberOfClass:[Song class]]){
                    [SpotlightHelper updateSpotlightIndexForSong:(Song *)obj];
                } else if([obj isMemberOfClass:[Artist class]]){
                    [SpotlightHelper updateSpotlightIndexForArtist:(Artist *)obj];
                } else if([obj isMemberOfClass:[Album class]]){
                    [SpotlightHelper updateSpotlightIndexForAlbum:(Album *)obj];
                }
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
    if(objects.count > 100){  //just picked a ranom large amount.
        [MRProgressOverlayView showOverlayAddedTo:[UIApplication sharedApplication].keyWindow
                                            title:@"Spotlight is indexing your media."
                                             mode:MRProgressOverlayViewModeIndeterminate
                                         animated:YES];
    }
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

@end
