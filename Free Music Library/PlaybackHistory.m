//
//  PlaybackHistory.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/15/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlaybackHistory.h"
#import "Stack.h"

@implementation PlaybackHistory
#define MAX_SONGS_SAVED 50
static Stack *stack;
static int count = 0;

+ (NSArray *)listOfRecentlyPlayedSongs
{
    if(! stack){
        stack = [[Stack alloc] init];
        return [stack arrayFromStack];
    }
    else
        return [stack arrayFromStack];
}

+ (void)addSongToHistory:(Song *)playedSong
{
    //add the song
    if(! stack){
        stack = [[Stack alloc] init];
        [stack pushObject:playedSong];
        count++;
    }
    else{
        [stack pushObject:playedSong];
        count++;
    }
    
    //check if too many songs are in the
    if(count > MAX_SONGS_SAVED)
        [stack discardBottomObject];
}

@end
