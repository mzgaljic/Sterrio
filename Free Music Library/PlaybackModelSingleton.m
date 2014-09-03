//
//  PlaybackModelSingleton.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/9/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlaybackModelSingleton.h"

@interface PlaybackModelSingleton ()
{
    NSUInteger indexOfNowPlayingSong;
    NSMutableArray *songLinkedList;
}
@end
@implementation PlaybackModelSingleton
@synthesize nowPlayingSong = _nowPlayingSong, printFrienlyNowPlayingSongNumber = _printFrienlyNowPlayingSongNumber, printFrienlyTotalSongsInCollectionNumber = _printFrienlyTotalSongsInCollectionNumber;


#pragma mark - Custom getters and setters
- (Song *)nowPlayingSong
{
    if(songLinkedList.count > 0)
        return [songLinkedList objectAtIndex:indexOfNowPlayingSong];
    else
        return nil;
}

#pragma mark - Initialization
+ (instancetype)createSingleton
{
    static id sharedMyModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyModel = [[self alloc] init];
    });
    return sharedMyModel;
}

- (id)init
{
    if(self = [super init]){
        _nowPlayingSong = nil;
        songLinkedList = [NSMutableArray array];
        indexOfNowPlayingSong = NSUIntegerMax;  //crazy index which will never be corrct in real world.
    }
    return self;
}
/**
#pragma mark - Changing the playback model
- (void)changeNowPlayingWithSong:(Song *)nextSong fromAllSongs:(NSArray *)allSongs indexOfNextSong:(NSUInteger)index
{
    [songLinkedList removeAllObjects];
    if(allSongs.count == 1){
        [songLinkedList addObject:nextSong];
        indexOfNowPlayingSong = index;
        _printFrienlyNowPlayingSongNumber = indexOfNowPlayingSong + 1;
        _printFrienlyTotalSongsInCollectionNumber = indexOfNowPlayingSong + 1;
        
    } else{
        NSRange rangeA;
        rangeA.location = 0;
        rangeA.length = index +1;
        //add items from beginning of allSongs array, up to and including the NowPlayingSong, to songLinkedList
        [songLinkedList addObjectsFromArray:[allSongs subarrayWithRange:rangeA]];
        
        NSRange rangeB;
        rangeB.location = index + 1;
        rangeB.length = allSongs.count - (index + 1);
        [songLinkedList addObjectsFromArray:[allSongs subarrayWithRange:rangeB]];
        indexOfNowPlayingSong = index;
        _printFrienlyNowPlayingSongNumber = indexOfNowPlayingSong + 1;
        _printFrienlyTotalSongsInCollectionNumber = allSongs.count;
    }
    
    _nowPlayingSong = nextSong;
}

- (void)changeNowPlayingWithSong:(Song *)nextSong fromPlaylist:(Playlist *)newPlaylist
{
    [songLinkedList removeAllObjects];
    //adding song and the other songs from this playlist containing song to the queue (maintaining order)
    if([newPlaylist.songsInThisPlaylist containsObject:nextSong]){
        NSUInteger indexOfNextSongInGivenPlaylist = [newPlaylist.songsInThisPlaylist indexOfObject:nextSong];
        NSRange rangeA;
        rangeA.location = 0;
        rangeA.length = indexOfNextSongInGivenPlaylist +1;
        //add items from beginning of playlist, up to and including the NowPlayingSong, to songLinkedList
        [songLinkedList addObjectsFromArray:[newPlaylist.songsInThisPlaylist subarrayWithRange:rangeA]];
        
        NSRange rangeB;
        rangeB.location = indexOfNextSongInGivenPlaylist + 1;
        rangeB.length = newPlaylist.songsInThisPlaylist.count - (indexOfNextSongInGivenPlaylist + 1);
        [songLinkedList addObjectsFromArray:[newPlaylist.songsInThisPlaylist subarrayWithRange:rangeB]];
        indexOfNowPlayingSong = indexOfNextSongInGivenPlaylist;
        _printFrienlyNowPlayingSongNumber = indexOfNowPlayingSong + 1;
        _printFrienlyTotalSongsInCollectionNumber = newPlaylist.songsInThisPlaylist.count;
        
        _nowPlayingSong = nextSong;
    }
}

- (void)changeNowPlayingWithSong:(Song *)nextSong fromAlbum:(Album *)newAlbum
{
    [songLinkedList removeAllObjects];
    //adding song and the other songs from this songs album to the queue (maintaining order)
    if([newAlbum.albumSongs containsObject:nextSong]){
        NSUInteger indexOfNextSongInGivenAlbum = [newAlbum.albumSongs indexOfObject:nextSong];
        NSRange rangeA;
        rangeA.location = 0;
        rangeA.length = indexOfNextSongInGivenAlbum +1;;
        //add items from beginning of album, up to and including the NowPlayingSong, to songLinkedList
        [songLinkedList addObjectsFromArray:[newAlbum.albumSongs subarrayWithRange:rangeA]];
        
        NSRange rangeB;
        rangeB.location = indexOfNextSongInGivenAlbum + 1;
        rangeB.length = newAlbum.albumSongs.count - (indexOfNextSongInGivenAlbum + 1);
        [songLinkedList addObjectsFromArray:[newAlbum.albumSongs subarrayWithRange:rangeB]];
        indexOfNowPlayingSong = indexOfNextSongInGivenAlbum;
        _printFrienlyNowPlayingSongNumber = indexOfNowPlayingSong + 1;
        _printFrienlyTotalSongsInCollectionNumber = newAlbum.albumSongs.count;
        
        _nowPlayingSong = nextSong;
    }
}

#pragma mark - Querying the model
- (NSArray *)listOfUpcomingSongsInQueue
{
    if(songLinkedList.count > 0){
        NSUInteger count = [songLinkedList count];
        //returns new array from the existing array, starting from indexOfNowPlaying song, up to the end.
        return [songLinkedList subarrayWithRange:(NSRange){count- indexOfNowPlayingSong, indexOfNowPlayingSong}];
    } else
        return nil;
}
*/
@end
