//
//  Song.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "Song.h"
#define SONG_NAME_KEY @"songName"
#define YOUTUBE_LINK_KEY @"youtubeLink"
#define ALBUM_ART_FILE_NAME_KEY @"albumArtFileName"
#define ALBUM_KEY @"album"
#define ARTIST_KEY @"artist"
#define GENRE_CODE_KEY @"songGenreCode"
#define ASSOCIATED_WITH_ALBUM_KEY @"associatedWithAlbum"

@implementation Song
@synthesize songName, youtubeLink, albumArtFileName = _albumArtFileName, album = _album, artist = _artist, genreCode, associatedWithAlbum = _associatedWithAlbum;

static  int const SAVE_SONG = 0;
static int const DELETE_SONG = 1;
static int const UPDATE_SONG = 2;

//custom property setter
- (void)setAlbum:(Album *)album
{
    if(album == nil){  //unAssociating this song from an album
        //needed so that when the old associated album is deleted, this song still has its art.
        [self makeCopyOfArtAndRename];
        
        [_album.albumSongs removeObject:self];
        _associatedWithAlbum = NO;
        
        if(_album.albumSongs.count == 0){  //if we just made the album empty
            if(self.artist)
                [[_artist allAlbums] removeObject:self.album];
            
            [_album deleteAlbum];
        }else if(self.artist)
            [[_artist allSongs] addObject:self];
        
        _album = nil;
        
    }else{  //associating the album with this song
        
        //when this song is associated w/ an album, add this song to its albumSongs array
        _album = album;
        if(!_album.albumSongs)
            _album.albumSongs = [NSMutableArray array];
        
        for(Song *aSong in _album.albumSongs){  //don't want to add duplicates to the list of songs (checking just in case)
            if([aSong isEqual:self])
                return;
        }
        
        [_album.albumSongs addObject:self];
        _associatedWithAlbum = YES;
        
        //finally, override old album art file name...possibly deleting the old album art if the two vary.
        //check if album has album art already. if not, make this the default for the album!
        if(_album.albumArtFileName){
            BOOL onDisk = [AlbumArtUtilities isAlbumArtAlreadySavedOnDisk:[NSString stringWithFormat:@"%@.png", self.songName]];
            //old album art is on disk
            if(onDisk)
                [self removeAlbumArt];
        }else{
            //reuse the album art as the new art for the album. Rename the file one disk though!
            [AlbumArtUtilities renameAlbumArtFileFrom:[NSString stringWithFormat:@"%@.png", self.songName]
                                                   to:[NSString stringWithFormat:@"%@.png", _album.albumName]];
            [_album setAlbumArt:[AlbumArtUtilities albumArtFileNameToUiImage:[NSString stringWithFormat:@"%@.png", _album.albumName]]];
        }
        _albumArtFileName = _album.albumArtFileName;
        
        if(self.artist)
            [[_artist allSongs] removeObject:self];
    }
}

- (void)setArtist:(Artist *)artist
{
    if([_artist isEqual:artist])
        return;
    else{
        if(_associatedWithAlbum){
            [_artist.allAlbums removeObject:_album];
            [_artist.allSongs removeObject:self];
            if(_artist.allSongs.count == 0 && _artist.allAlbums.count ==0)
                [_artist deleteArtist];
        }else{
            [[_artist allSongs] removeObject:self];
            if(! [artist.allSongs containsObject:self])
                [[artist allSongs] addObject:self];
            if(_artist.allSongs.count == 0 && _artist.allAlbums.count ==0)
                [_artist deleteArtist];
        }
    }
    
    _artist = artist;
}
//end of custom setters

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self){
        self.songName = [aDecoder decodeObjectForKey:SONG_NAME_KEY];
        self.youtubeLink = [aDecoder decodeObjectForKey:YOUTUBE_LINK_KEY];
        _albumArtFileName = [aDecoder decodeObjectForKey:ALBUM_ART_FILE_NAME_KEY];
        self.album = [aDecoder decodeObjectForKey:ALBUM_KEY];
        self.artist = [aDecoder decodeObjectForKey:ARTIST_KEY];
        self.genreCode = [aDecoder decodeIntForKey:GENRE_CODE_KEY];
        _associatedWithAlbum = [aDecoder decodeBoolForKey:ASSOCIATED_WITH_ALBUM_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.songName forKey:SONG_NAME_KEY];
    [aCoder encodeObject:self.youtubeLink forKey:YOUTUBE_LINK_KEY];
    [aCoder encodeObject:self.albumArtFileName forKey:ALBUM_ART_FILE_NAME_KEY];
    [aCoder encodeObject:self.album forKey:ALBUM_KEY];
    [aCoder encodeObject:self.artist forKey:ARTIST_KEY];
    [aCoder encodeInteger:self.genreCode forKey:GENRE_CODE_KEY];
    [aCoder encodeBool:_associatedWithAlbum forKey:ASSOCIATED_WITH_ALBUM_KEY];
}

+ (NSArray *)loadAll  //loads array containing all of the saved songs
{
    NSData *data = [NSData dataWithContentsOfURL:[FileIOConstants createSingleton].songsFileURL];
    if(!data){
        //if no songs exist yet (file not yet written to disk), return empty array
        return [NSMutableArray array];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];  //decode loaded data
}

+ (void)reSortModel
{
    NSMutableArray *songs = (NSMutableArray *)[Song loadAll];
    if([AppEnvironmentConstants smartAlphabeticalSort])
        [Song sortExistingSongsWithSmartSort: &songs];
    else
        [Song sortExistingSongsAlphabetically: &songs];
    
    //save changes to model on disk
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:songs];  //encode songs
    [fileData writeToURL:[FileIOConstants createSingleton].songsFileURL atomically:YES];
}

- (BOOL)saveSong  //saves the current song (instance of this class) to the list of all songs on disk
{
    return [self performModelAction:SAVE_SONG];
}

- (BOOL)deleteSong
{
    return [self performModelAction:DELETE_SONG];
}

- (BOOL)updateExistingSong
{
    return [self performModelAction:UPDATE_SONG];
}

- (BOOL)updateExistingSongUsingOldSong
{
    return [self performModelAction:UPDATE_SONG];
}

- (BOOL)performModelAction:(int)desiredActionConst  //does the 'hard work' of altering the model.
{
    NSMutableArray *songs = (NSMutableArray *)[Song loadAll];
    
    switch (desiredActionConst) {
        case SAVE_SONG:
            [songs insertObject:self atIndex:0]; //new songs added to array will appear at top of 'list'
            
            //update the artist details for this song
            if(_artist){
                [_artist.allSongs addObject:self];
            }
            
            break;
            
        case DELETE_SONG:  //This class is responsible for deleting songs from albums
        {
            [self removeAlbumArt]; //delete album art from disk if we need to
            
            self.artist = nil;
            
            if(_album){
                if(_album.albumSongs.count == 1){  //last song in album, album about to become empty
                    [[_artist allAlbums] removeObject:_album];
                }
                //if album continues to exist, no action needed
            } else{
                //if not part of album, just remove this song from list of artist songs
                [[_artist allSongs] removeObject:self];
            }
            
            BOOL deletedAlbum = NO;
            Song *thisSong = songs[[songs indexOfObject:self]];
            Album *thisSongsAlbum = thisSong.album;
            
            if(thisSong.associatedWithAlbum){
                //is this the last song in an album? If so, we need to delete the album too.
                if(thisSongsAlbum.albumSongs.count == 1){
                    [songs removeObject:self];  //delete the song
                    [thisSongsAlbum.albumSongs removeObject:self];
                    [thisSongsAlbum deleteAlbum];  //deleting album also deletes songs
                    deletedAlbum = YES;
                }
                
                if(! deletedAlbum){
                    //each song has its own album object, so we need to enforce the change across all songs
                    for(Song *aSong in songs){  //#Inefficient
                        if([aSong.album isEqual:self.album]){  //is this song part of same album?
                            [aSong.album.albumSongs removeObject:self];
                            [aSong.album updateExistingAlbum];
                        }
                    }
                    [songs removeObject:self];
                }

            } else{  //song not associated with an album
                [songs removeObject:self];
            }
            
            break;
        }
    
        case UPDATE_SONG:
            //replace the old object saved in the array (the model) with the current object
            if(songs.count > 0){
                [songs replaceObjectAtIndex:[songs indexOfObject:self] withObject:self];
            }
            
            break;
            
        default:
            return NO;
            
    } //end of swtich
    
    if([AppEnvironmentConstants smartAlphabeticalSort])
        [Song sortExistingSongsWithSmartSort: &songs];
    else
        [Song sortExistingSongsAlphabetically: &songs];
    
    //save changes to model on disk
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:songs];  //encode songs
    return [fileData writeToURL:[FileIOConstants createSingleton].songsFileURL atomically:YES];
}

- (BOOL)setAlbumArt:(UIImage *)image
{
    BOOL success = NO;
    NSString *artFileName;
    
    if(! _associatedWithAlbum)
        artFileName = [NSString stringWithFormat:@"%@.png", self.songName];
    else
        artFileName = [NSString stringWithFormat:@"%@.png", _album.albumName];
    
    //save and compress the UIImage to disk
    if([AlbumArtUtilities isAlbumArtAlreadySavedOnDisk: artFileName])
        success = YES;
    else
        success = [AlbumArtUtilities saveAlbumArtFileWithName:artFileName andImage:image];
    
    _albumArtFileName = artFileName;
    return success;
}

- (BOOL)removeAlbumArt
{
    BOOL success = NO;
    if(_albumArtFileName){
        if(! _associatedWithAlbum){  //can definitely remove the image
            //remove file from disk
            [AlbumArtUtilities deleteAlbumArtFileWithName:_albumArtFileName];
            
            //made albumArtFileName property nil
            _albumArtFileName = nil;
        }
        else{
            //album wont exist much longer, is being deleted now. can erase album art...
            if(_album.albumSongs.count == 1){
                //remove file from disk
                [AlbumArtUtilities deleteAlbumArtFileWithName:_albumArtFileName];
                
                //made albumArtFileName property nil
                _albumArtFileName = nil;
            }
        }
    }
    
    return success;
}

- (BOOL)makeCopyOfArtAndRename
{
    return [AlbumArtUtilities makeCopyOfArtWithName:[NSString stringWithFormat:@"%@.png", _album.albumName] andNameIt:[NSString stringWithFormat:@"%@.png", self.songName]];
}

+ (void)sortExistingSongsAlphabetically:(NSMutableArray **)songModel
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"songName" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    [*songModel sortUsingDescriptors:[NSArray arrayWithObject:sort]];
}

+ (void)sortExistingSongsWithSmartSort:(NSMutableArray **)songModel
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"songName" ascending:YES selector:@selector(smartSort:)];
    [*songModel sortUsingDescriptors:[NSArray arrayWithObject:sort]];
}

- (NSMutableArray *)insertNewSongIntoAlphabeticalArray:(Song *)unInsertedSong
{
    return nil;
}

- (BOOL)isEqual:(id)object
{
    if(self == object)  //same object instance
        return YES;
    if(!object || ![object isMemberOfClass:[self class]])  //object is nil or not an album object
        return NO;
    
    return ([self customSmartSongComparison:(Song *)object]) ? YES : NO;
}

- (BOOL)customSmartSongComparison:(Song *)mysterySong
{
    BOOL sameSongName = NO, sameAlbumName = NO, sameArtistName = NO;
    //check if album names are equal -remember, every album name needs to be unique.
    if([self.album.albumName isEqualToString:mysterySong.album.albumName])
        sameAlbumName = YES;
    if([self.songName isEqualToString:mysterySong.songName])
        sameSongName = YES;
    if([self.artist.artistName isEqualToString:mysterySong.artist.artistName])
        sameArtistName = YES;
    
    return (sameSongName && (sameAlbumName || sameArtistName)) ? YES : NO;
}

-(NSUInteger)hash
{
    NSUInteger result = 1;
    NSUInteger prime = 31;
    NSUInteger yesPrime = 1231;
    NSUInteger noPrime = 1237;
    
    // Add any object that already has a hash function (NSString)
    result = prime * result + [self.songName hash];
    result = prime * result + [self.youtubeLink hash];
    result = prime * result + [self.albumArtFileName hash];
    
    result = prime * result + [self.album.albumName hash];
    result = prime * result + [self.album.releaseDate hash];
    result = prime * result + [self.album.albumArtFileName hash];
    result = prime * result + [self.album.albumSongs hash];
    
    result = prime * result + [self.artist.artistName hash];
    
    //Add primitive variables (int)
    result = prime * result + self.genreCode;
    result = prime * result + self.album.genreCode;
    
    //Boolean values (BOOL)
    result = (prime * result + self.associatedWithAlbum) ? yesPrime : noPrime;
    
    return result;
}

@end