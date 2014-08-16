//
//  AppDelegateSetupHelper.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/9/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AppDelegateSetupHelper.h"

@implementation AppDelegateSetupHelper
static BOOL PRODUCTION_MODE;

+ (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

+ (void)setUpNSCodingFilePaths
{
    //find documents directory within this apps home directory
    NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    [[FileIOConstants createSingleton] setSongsFileURL:[[urls lastObject] URLByAppendingPathComponent:@"Lib_Songs.data"]];
    [[FileIOConstants createSingleton] setAlbumsFileURL:[[urls lastObject] URLByAppendingPathComponent:@"Lib_Albums.data"]];
    [[FileIOConstants createSingleton] setArtistsFileURL:[[urls lastObject] URLByAppendingPathComponent:@"Lib_Artists.data"]];
    [[FileIOConstants createSingleton] setPlaylistsFileURL:[[urls lastObject] URLByAppendingPathComponent:@"Lib_Playlists.data"]];
    [[FileIOConstants createSingleton] setTempPlaylistsFileURL:[[urls lastObject] URLByAppendingPathComponent:@"Lib_TempPlaylist.data"]];
    [[FileIOConstants createSingleton] setGenresFileURL:[[urls lastObject] URLByAppendingPathComponent:@"Lib_Genres.data"]];
    
    //create url's for now playing queue!
}

+ (void)setUpFakeLibraryContent
{
    [AppDelegateSetupHelper setProductionModeValue];
    
    if(!PRODUCTION_MODE){
        //make the fake contents
        Artist *artist1 = [[Artist alloc] init];
        artist1.artistName = @"Leona Lewis";
        Album *album1 = [[Album alloc] init];
        album1.albumName = @"Echo (Deluxe Version)";
        album1.artist = artist1;
        [album1 setAlbumArt:[UIImage imageNamed:@"Echo (Deluxe Version)"]];
        //in real code...
        //[album1 setAlbumArt:[AlbumArtUtilities albumArtFileNameToUiImage:@"Echo (Deluxe Version).png"]];
        Song *song1 = [[Song alloc] init];
        song1.songName = @"I Got You";
        song1.youtubeId = @"psIfrJ210Ds";
        song1.artist = artist1;
        song1.album = album1;
        [song1 setAlbumArt:[UIImage imageNamed:@"Echo (Deluxe Version)"]];
        [artist1 saveArtist];
        [album1 saveAlbum];
        [song1 saveSong];
        //-----------------
        Artist *artist2 = [[Artist alloc] init];
        artist2.artistName = @"Colbie Caillat";
        Album *album2 = [[Album alloc] init];
        album2.albumName = @"Hold On - Single";
        album2.artist = artist2;
        [album2 setAlbumArt:[UIImage imageNamed:@"Hold On - Single"]];
        Song *song2 = [[Song alloc] init];
        song2.songName = @"Hold On";
        song2.youtubeId = @"bhA3d1i0kNY";
        song2.artist = artist2;
        song2.album = album2;
        [song2 setAlbumArt:[UIImage imageNamed:@"Hold On - Single"]];
        [artist2 saveArtist];
        [album2 saveAlbum];
        [song2 saveSong];
        //-----------------
        Artist *artist3 = [[Artist alloc] init];
        artist3.artistName = @"Betty Who";
        Album *album3 = [[Album alloc] init];
        album3.albumName = @"The Movement - EP";
        album3.artist = artist3;
        [album3 setAlbumArt:[UIImage imageNamed:@"The Movement - EP"]];
        Song *song3 = [[Song alloc] init];
        song3.songName = @"Somebody Loves You";
        song3.youtubeId = @"gTVFQHuIg2I";
        song3.artist = artist3;
        song3.album = album3;
        [song3 setAlbumArt:[UIImage imageNamed:@"The Movement - EP"]];
        [artist3 saveArtist];
        [album3 saveAlbum];
        [song3 saveSong];
        //-----------------
        Artist *artist4 = [[Artist alloc] init];
        artist4.artistName = @"Lionel Richie";
        Album *album4 = [[Album alloc] init];
        album4.albumName = @"20th Century Masters - The Millennium Collection- The Best of Lionel Richie";
        album4.artist = artist4;
        [album4 setAlbumArt:[UIImage imageNamed:@"20th Century Masters - The Millennium Collection- The Best of Lionel Richie"]];
        Song *song4 = [[Song alloc] init];
        song4.songName = @"You Are";
        song4.youtubeId = @"AJwoY56tLrk";
        song4.artist = artist4;
        song4.album = album4;
        [song4 setAlbumArt:[UIImage imageNamed:@"20th Century Masters - The Millennium Collection- The Best of Lionel Richie"]];
        [artist4 saveArtist];
        [album4 saveAlbum];
        [song4 saveSong];
        //-----------------
        Artist *artist5 = [[Artist alloc] init];
        artist5.artistName = @"The Cab";
        Album *album5 = [[Album alloc] init];
        album5.albumName = @"Whisper War";
        album5.artist = artist5;
        [album5 setAlbumArt:[UIImage imageNamed:@"Whisper War"]];
        Song *song5 = [[Song alloc] init];
        song5.songName = @"Risky Business";
        song5.youtubeId = @"CIZxhdl2JvU";
        song5.artist = artist5;
        song5.album = album5;
        [song5 setAlbumArt:[UIImage imageNamed:@"Whisper War"]];
        Song *song6 = [[Song alloc] init];
        song6.songName = @"That '70s Song";
        song6.youtubeId = @"0REJoFKfDHE";
        song6.artist = artist5;
        song6.album = album5;
        [song6 setAlbumArt:[UIImage imageNamed:@"Whisper War"]];
        [artist5 saveArtist];
        [album5 saveAlbum];
        [song5 saveSong];
        [song6 saveSong];
        //-----------------
        Artist *artist6 = [[Artist alloc] init];
        artist6.artistName = @"Various Artists";
        Album *album6 = [[Album alloc] init];
        album6.albumName = @"Frozen (Original Motion Picture Soundtrack)";
        album6.artist = artist6;
        [album6 setAlbumArt:[UIImage imageNamed:@"Frozen (Original Motion Picture Soundtrack)"]];
        Song *song7 = [[Song alloc] init];
        song7.songName = @"Do You Want To Build A Snowman?";
        song7.youtubeId = @"9YwXff-i1fY";
        song7.artist = artist6;
        song7.album = album6;
        [song7 setAlbumArt:[UIImage imageNamed:@"Frozen (Original Motion Picture Soundtrack)"]];
        Song *song8 = [[Song alloc] init];
        song8.songName = @"Let It Go";
        song8.youtubeId = @"YVVTZgwYwVo";
        song8.artist = artist6;
        song8.album = album6;
        [song8 setAlbumArt:[UIImage imageNamed:@"Frozen (Original Motion Picture Soundtrack)"]];
        [artist6 saveArtist];
        [album6 saveAlbum];
        [song7 saveSong];
        [song8 saveSong];
        //-----------------
        Artist *artist7 = [[Artist alloc] init];
        artist7.artistName = @"Paper Route";
        Album *album7 = [[Album alloc] init];
        album7.albumName = @"You and I - Single";
        album7.artist = artist7;
        [album7 setAlbumArt:[UIImage imageNamed:@"You and I - Single"]];
        Song *song9 = [[Song alloc] init];
        song9.songName = @"You And I";
        song9.youtubeId = @"GavKw-yDo98";
        song9.artist = artist7;
        song9.album = album7;
        [song9 setAlbumArt:[UIImage imageNamed:@"You and I - Single"]];
        [artist7 saveArtist];
        [album7 saveAlbum];
        [song9 saveSong];
        //-----------------
        Artist *artist8 = [[Artist alloc] init];
        artist8.artistName = @"Angels & Airwaves";
        Album *album8 = [[Album alloc] init];
        album8.albumName = @"We Don't Need to Whisper";
        album8.artist = artist8;
        [album7 setAlbumArt:[UIImage imageNamed:@"We Don't Need to Whisper"]];
        Song *song10 = [[Song alloc] init];
        song10.songName = @"The Adventure";
        song10.youtubeId = @"JMl8cQjBfqk";
        song10.artist = artist8;
        song10.album = album8;
        [song10 setAlbumArt:[UIImage imageNamed:@"We Don't Need to Whisper"]];
        [artist8 saveArtist];
        [album8 saveAlbum];
        [song10 saveSong];
    }
}

+ (void)setAppSettingsAppLaunchedFirstTime:(BOOL)firstTime
{
    if(firstTime){
        [AppEnvironmentConstants setPreferredSizeSetting:3];
        [AppEnvironmentConstants setBoldNames:YES];
        [AppEnvironmentConstants setPreferredWifiStreamSetting:720];
        [AppEnvironmentConstants setPreferredCellularStreamSetting:360];
        [AppEnvironmentConstants setSmartAlphabeticalSort:YES];
        [AppEnvironmentConstants set_iCloudSettingsSync:NO];
        
        [[NSUserDefaults standardUserDefaults] setInteger:3 forKey:PREFERRED_SIZE_KEY];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:BOLD_NAME];
        [[NSUserDefaults standardUserDefaults] setInteger:720 forKey:PREFERRED_WIFI_VALUE_KEY];
        [[NSUserDefaults standardUserDefaults] setInteger:360 forKey:PREFERRED_CELL_VALUE_KEY];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:SMART_SORT];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:ICLOUD_SYNC];
    } else{
        //load users last settings from disk before setting these values.
        [AppEnvironmentConstants setPreferredSizeSetting:[[NSUserDefaults standardUserDefaults] integerForKey:PREFERRED_SIZE_KEY]];
        [AppEnvironmentConstants setBoldNames:[[NSUserDefaults standardUserDefaults] boolForKey:BOLD_NAME]];
        [AppEnvironmentConstants setPreferredWifiStreamSetting:[[NSUserDefaults standardUserDefaults] integerForKey:PREFERRED_WIFI_VALUE_KEY]];
        [AppEnvironmentConstants setPreferredCellularStreamSetting:[[NSUserDefaults standardUserDefaults] integerForKey:PREFERRED_CELL_VALUE_KEY]];
        [AppEnvironmentConstants setSmartAlphabeticalSort:[[NSUserDefaults standardUserDefaults] boolForKey:SMART_SORT]];
        [AppEnvironmentConstants set_iCloudSettingsSync:[[NSUserDefaults standardUserDefaults] boolForKey:ICLOUD_SYNC]];
    }
}


@end
