//
//  SpotlightHelper.m
//  Sterrio
//
//  Created by Mark Zgaljic on 7/10/15.
//  Copyright © 2015 Mark Zgaljic Apps. All rights reserved.
//

#import "SpotlightHelper.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "SongAlbumArt.h"
#import "AppEnvironmentConstants.h"

@implementation SpotlightHelper

+ (void)addSongToSpotlightIndex:(Song *)aSong
{
    if(! [AppEnvironmentConstants isUserOniOS9OrAbove])
        return;
    
    // Create an attribute set for an item that represents audio-visual content.
    CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeAudio];
    // Properties that describe attributes of the item such as title, description, and image.
    attributeSet.title = aSong.songName;
    attributeSet.duration = aSong.duration;
    attributeSet.originalSource = @"YouTube";
    if(aSong.artist)
        attributeSet.artist = aSong.artist.artistName;
    if(aSong.album)
        attributeSet.album = aSong.album.albumName;
    attributeSet.thumbnailData = aSong.albumArt.image;
    
    // Create a searchable item, specifying its ID, associated domain, and attributes.
    NSString *domainId = [SpotlightHelper spotlightIndexItemDomainIdGivenSong:aSong];
    CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:aSong.uniqueId
                                                               domainIdentifier:domainId
                                                                   attributeSet:attributeSet];
    item.expirationDate = [NSDate distantFuture];
    
    // Index the items.
    [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:@[item]
                                                   completionHandler: ^(NSError * __nullable error) {
                                                       if(error){
                                                           NSLog(@"Error indexing item(s) in Spotlight.");
                                                       } else{
                                                           NSLog(@"Item(s) indexed in Spotlight.");
                                                       }
                                                   }];
}

+ (void)removeSongFromSpotlightIndex:(Song *)aSong
{
    if(! [AppEnvironmentConstants isUserOniOS9OrAbove])
        return;
    
    NSString *domainId = [SpotlightHelper spotlightIndexItemDomainIdGivenSong:aSong];
    [SpotlightHelper removeSongIndexFromSpotlightWithDomainId:domainId songId:aSong.uniqueId];
}
+ (void)removeAlbumSongsFromSpotlightIndex:(Album *)anAlbum
{
    if(! [AppEnvironmentConstants isUserOniOS9OrAbove])
        return;
    
    NSString *domainId = [SpotlightHelper spotlightIndexItemDomainIdGivenAlbum:anAlbum];
    [SpotlightHelper removeSongIndexFromSpotlightWithDomainId:domainId songId:nil];
}
+ (void)removeArtistSongsFromSpotlightIndex:(Artist *)anArtist
{
    if(! [AppEnvironmentConstants isUserOniOS9OrAbove])
        return;
    
    NSString *domainId = [SpotlightHelper spotlightIndexItemDomainIdGivenArtist:anArtist];
    [SpotlightHelper removeSongIndexFromSpotlightWithDomainId:domainId songId:nil];
}

+ (void)removeSongIndexFromSpotlightWithDomainId:(NSString *)domainId songId:(NSString *)songId
{
    if(! [AppEnvironmentConstants isUserOniOS9OrAbove])
        return;
    
    if(domainId == nil && songId != nil){
        [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithIdentifiers:@[songId]
                                                                       completionHandler:^(NSError * __nullable error) {
                                                                           if(error)
                                                                               NSLog(@"Failed to remove song from spotlight index.");
                                                                       }];
    } else{
        [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithDomainIdentifiers:@[domainId]
                                                                             completionHandler:^(NSError * __nullable error) {
                                                                                 if(error)
                                                                                     NSLog(@"Failed to remove song from spotlight index.");
                                                                             }];
    }
}

+ (void)updateSpotlightIndexForSong:(Song *)aSong
{
    if(! [AppEnvironmentConstants isUserOniOS9OrAbove])
        return;
    
    //CoreSpotlight seems to update the existing indexed item if you re-add it.
    [SpotlightHelper addSongToSpotlightIndex:aSong];
}

+ (NSString *)spotlightIndexItemDomainIdGivenSong:(Song *)aSong
{
    if(aSong == nil)
        return nil;
    NSMutableString *domainId = [NSMutableString new];
    if(aSong.artist)
        [domainId appendString:aSong.artist.uniqueId];
    if(aSong.album){
        [domainId appendString:@"."];
        [domainId appendString:aSong.album.uniqueId];
    }
    if(domainId.length == 0)
        return nil;
    
    //if song has artist and album, domain id will look like: artistName.albumName
    return domainId;
}

+ (NSString *)spotlightIndexItemDomainIdGivenAlbum:(Album *)anAlbum
{
    if(anAlbum == nil)
        return nil;
    NSMutableString *domainId = [NSMutableString new];
    if(anAlbum.artist)
        [domainId appendString:anAlbum.artist.uniqueId];
    [domainId appendString:@"."];
    [domainId appendString:anAlbum.uniqueId];
    
    if(domainId.length == 0)
        return nil;
    //if song has artist and album, domain id will look like: artistName.albumName
    return domainId;
}

+ (NSString *)spotlightIndexItemDomainIdGivenArtist:(Artist *)anArtist
{
    if(anArtist == nil)
        return nil;
    return anArtist.uniqueId;
}

@end
