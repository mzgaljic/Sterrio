//
//  PlaylistSongItemTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/13/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlaylistSongItemTableViewController.h"
#define Done_String @"Done"
#define AddLater_String @"Add later"
#define Cancel_String @"Cancel"

@interface PlaylistSongItemTableViewController()
@property (nonatomic, strong) NSMutableArray *allSongs;
@end

@implementation PlaylistSongItemTableViewController
@synthesize songsSelected = _songsSelected, receiverPlaylist = _receiverPlaylist, allSongs = _allSongs;
static BOOL PRODUCTION_MODE;

- (NSMutableArray *) results
{
    if(! _results){
        _results = [[NSMutableArray alloc] init];
    }
    return _results;
}

- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _songsSelected = [NSMutableArray array];
    
    self.tableView.allowsMultipleSelection = YES;
    
    //init tableView model
    NSString *newPlaylistName = [self obtainPlaylistNameFromTempFile];
    _receiverPlaylist = [[Playlist alloc] init];
    _receiverPlaylist.playlistName = newPlaylistName;
    
    _allSongs = [NSMutableArray arrayWithArray:[Song loadAll]];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setProductionModeValue];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _allSongs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"playlistSongItemPickerCell" forIndexPath:indexPath];
    
    // Configure the cell...
    Song *song = [_allSongs objectAtIndex:indexPath.row];  //get song object at this index
    
    //init cell fields
    cell.textLabel.text = song.songName;
    NSString *detailStringLabel = [NSString stringWithFormat:@"%@-%@", song.artist.artistName, song.album.albumName];
    cell.detailTextLabel.text = detailStringLabel;
    
    if(PRODUCTION_MODE)
        cell.imageView.image = [AlbumArtUtilities albumArtFileNameToUiImage: song.albumArtFileName];
    else
        cell.imageView.image = [UIImage imageNamed:song.album.albumName];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //obtain object for the tapped song
    Song *song = [_allSongs objectAtIndex:indexPath.row];
    
    if([_songsSelected containsObject:song]){  //deselect song
        if(_songsSelected.count == 1)
            self.rightBarButton.title = AddLater_String;
        
        [self.songsSelected removeObject:song];
    }
    else{  //select song
        if(_songsSelected.count == 0)
            self.rightBarButton.title = Done_String;
        
        [self.songsSelected addObject:song];
    }
}

- (IBAction)rightBarButtonTapped:(id)sender
{
    if([self.rightBarButton.title isEqualToString:Done_String]){
        //add all selected songs to the playlists songs array (the model on disk), "pop" modal view
        [_receiverPlaylist.songsInThisPlaylist addObjectsFromArray:self.songsSelected];
        [_receiverPlaylist savePlaylist];
        [self dismissViewControllerAnimated:YES completion:nil];
        
    } else if([self.rightBarButton.title isEqualToString:AddLater_String]){
        //leave playlist empty and "pop" this modal view off the screen
        [_receiverPlaylist savePlaylist];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)leftBarButtonTapped:(id)sender
{
    if([self.leftBarButton.title isEqualToString:Cancel_String]){
        //cancel the creation of the playlist and "pop" this modal view off the screen.
        [_receiverPlaylist deletePlaylist];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (NSString *)obtainPlaylistNameFromTempFile
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"temp file"];
    
    NSString *returnString = [NSString stringWithContentsOfFile:dataPath encoding:NSUTF8StringEncoding error:nil];
    //delete the file
    [[NSFileManager defaultManager] removeItemAtPath:dataPath error:nil];
    
    return returnString;
}
@end
