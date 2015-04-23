//
//  KnownTypes.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/15/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#ifndef Free_Music_Library_KnownTypes_h
#define Free_Music_Library_KnownTypes_h


#endif


typedef enum{
    SONG_DATA_SRC_TYPE_Default,
    SONG_DATA_SRC_TYPE_Playlist_MultiSelect
} SONG_DATA_SRC_TYPE;

typedef enum{
    ALBUM_DATA_SRC_TYPE_Default,
    ALBUM_DATA_SRC_TYPE_Single_Album_Picker
} ALBUM_DATA_SRC_TYPE;

typedef enum{
    ARTIST_DATA_SRC_TYPE_Default,
    ARTIST_DATA_SRC_TYPE_Single_Artist_Picker
} ARTIST_DATA_SRC_TYPE;

typedef enum{
    PLAYLIST_DATA_SRC_TYPE_Default
} PLAYLIST_DATA_SRC_TYPE;

typedef enum{
    PLAYLIST_STATUS_In_Creation,
    PLAYLIST_STATUS_Created_But_Empty,
    PLAYLIST_STATUS_Normal_Playlist
} PLAYLIST_STATUS;