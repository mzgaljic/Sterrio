//
//  AppDelegate.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/20/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AppDelegate.h"
#import "Song.h"
#import "Album.h"
#import "Artist.h"
#import "Playlist.h"
#import "GenreConstants.h"
#import "FileIOConstants.h"

@implementation AppDelegate

static const BOOL PRODUCTION_MODE = NO;

- (void)setUpNSCodingFilePaths
{
    //find documents directory within this apps home directory
    NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    [[FileIOConstants createSingleton] setSongsFileURL:[[urls lastObject] URLByAppendingPathComponent:@"Lib_Songs.data"]];
    [[FileIOConstants createSingleton] setAlbumsFileURL:[[urls lastObject] URLByAppendingPathComponent:@"Lib_Albums.data"]];
    [[FileIOConstants createSingleton] setArtistsFileURL:[[urls lastObject] URLByAppendingPathComponent:@"Lib_Artists.data"]];
    [[FileIOConstants createSingleton] setPlaylistsFileURL:[[urls lastObject] URLByAppendingPathComponent:@"Lib_Playlists.data"]];
    [[FileIOConstants createSingleton] setGenresFileURL:[[urls lastObject] URLByAppendingPathComponent:@"Lib_Genres.data"]];

}

- (void)setUpGenreConstants
{
    GenreConstants *genres = [GenreConstants createSingleton];
    //initialize the NSDictionary containing genre strings and codes (genre constants).
    NSArray *keysArray = [GenreConstants keysForGenreSingleton];
    NSArray *objectsArray = [GenreConstants objectsForGenreSingleton];
    genres.singletonGenreDictionary = [[NSDictionary alloc] initWithObjects: objectsArray forKeys: keysArray];
}

- (void)setUpFakeLibraryContent
{
    NSArray *songs = [NSMutableArray arrayWithArray:[Song loadAll]];
    NSArray *albums = [NSMutableArray arrayWithArray:[Album loadAll]];
    if(songs.count == 0 && albums.count == 0 && !PRODUCTION_MODE){
        //make the fake contents
        
        Artist *artist1 = [[Artist alloc] init];
        artist1.artistName = @"Leona Lewis";
        Album *album1 = [[Album alloc] init];
        album1.albumName = @"Echo (Deluxe Version)";
        album1.artist = artist1;
        album1.albumArtFileName = @"Echo (Deluxe Version).png";
        Song *song1 = [[Song alloc] init];
        song1.songName = @"Bleeding Love";
        song1.artist = artist1;
        song1.album = album1;
        song1.albumArtFileName = @"Echo (Deluxe Version).png";
        song1.associatedWithAlbum = YES;
        [artist1 save];
        [album1 saveAlbum];
        [song1 saveSong];
        //-----------------
        Artist *artist2 = [[Artist alloc] init];
        artist2.artistName = @"Colbie Caillat";
        Album *album2 = [[Album alloc] init];
        album2.albumName = @"Hold On - Single";
        album2.artist = artist2;
        album2.albumArtFileName = @"Hold On - Single.png";
        Song *song2 = [[Song alloc] init];
        song2.songName = @"Hold On";
        song2.artist = artist2;
        song2.album = album2;
        song2.albumArtFileName = @"Hold On - Single.png";
        song2.associatedWithAlbum = YES;
        [artist2 save];
        [album2 saveAlbum];
        [song2 saveSong];
        //-----------------
        Artist *artist3 = [[Artist alloc] init];
        artist3.artistName = @"Betty Who";
        Album *album3 = [[Album alloc] init];
        album3.albumName = @"The Movement - EP";
        album3.artist = artist3;
        album3.albumArtFileName = @"The Movement - EP.png";
        Song *song3 = [[Song alloc] init];
        song3.songName = @"Somebody Loves You";
        song3.artist = artist3;
        song3.album = album3;
        song3.albumArtFileName = @"The Movement - EP.png";
        song3.associatedWithAlbum = YES;
        [artist3 save];
        [album3 saveAlbum];
        [song3 saveSong];
        //-----------------
        Artist *artist4 = [[Artist alloc] init];
        artist4.artistName = @"Lionel Richie";
        Album *album4 = [[Album alloc] init];
        album4.albumName = @"20th Century Masters - The Millennium Collection- The Best of Lionel Richie";
        album4.artist = artist4;
        album4.albumArtFileName = @"20th Century Masters - The Millennium Collection- The Best of Lionel Richie.png";
        Song *song4 = [[Song alloc] init];
        song4.songName = @"You Are";
        song4.artist = artist4;
        song4.album = album4;
        song4.albumArtFileName = @"20th Century Masters - The Millennium Collection- The Best of Lionel Richie.png";
        song4.associatedWithAlbum = YES;
        [artist4 save];
        [album4 saveAlbum];
        [song4 saveSong];
        //-----------------
        Artist *artist5 = [[Artist alloc] init];
        artist5.artistName = @"The Cab";
        Album *album5 = [[Album alloc] init];
        album5.albumName = @"Whisper War";
        album5.artist = artist5;
        album5.albumArtFileName = @"Whisper War.png";
        Song *song5 = [[Song alloc] init];
        song5.songName = @"Risky Business";
        song5.artist = artist5;
        song5.album = album5;
        song5.albumArtFileName = @"Whisper War.png";
        song5.associatedWithAlbum = YES;
        Song *song6 = [[Song alloc] init];
        song6.songName = @"That '70s Song";
        song6.artist = artist5;
        song6.album = album5;
        song6.albumArtFileName = @"Whisper War.png";
        song6.associatedWithAlbum = YES;
        [artist5 save];
        [album5 saveAlbum];
        [song5 saveSong];
        [song6 saveSong];
        //-----------------
        Artist *artist6 = [[Artist alloc] init];
        artist6.artistName = @"Various Artists";
        Album *album6 = [[Album alloc] init];
        album6.albumName = @"Frozen (Original Motion Picture Soundtrack)";
        album6.artist = artist6;
        album6.albumArtFileName = @"Frozen (Original Motion Picture Soundtrack).png";
        Song *song7 = [[Song alloc] init];
        song7.songName = @"Do You Want To Build A Snowman?";
        song7.artist = artist6;
        song7.album = album6;
        song7.albumArtFileName = @"Frozen (Original Motion Picture Soundtrack).png";
        song7.associatedWithAlbum = YES;
        Song *song8 = [[Song alloc] init];
        song8.songName = @"Let It Go";
        song8.artist = artist6;
        song8.album = album6;
        song8.albumArtFileName = @"Frozen (Original Motion Picture Soundtrack).png";
        song8.associatedWithAlbum = YES;
        [artist6 save];
        [album6 saveAlbum];
        [song7 saveSong];
        [song8 saveSong];
        //-----------------
        Artist *artist7 = [[Artist alloc] init];
        artist7.artistName = @"Paper Route";
        Album *album7 = [[Album alloc] init];
        album7.albumName = @"You and I - Single";
        album7.artist = artist7;
        album7.albumArtFileName = @"You and I - Single.png";
        Song *song9 = [[Song alloc] init];
        song9.songName = @"You And I";
        song9.artist = artist7;
        song9.album = album7;
        song9.albumArtFileName = @"You and I - Single.png";
        song9.associatedWithAlbum = YES;
        [artist7 save];
        [album7 saveAlbum];
        [song9 saveSong];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.

    [self setUpGenreConstants];
    [self setUpNSCodingFilePaths];
    [self setUpFakeLibraryContent];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    
    //do not need to save model class data, they are saved upon creation to disk (and resaved when altered).
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
