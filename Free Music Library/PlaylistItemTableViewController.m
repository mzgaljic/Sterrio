//
//  PlaylistItemTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/27/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlaylistItemTableViewController.h"

@interface PlaylistItemTableViewController()
@property (nonatomic, assign) int lastTableViewModelCount;
@end

@implementation PlaylistItemTableViewController
@synthesize playlist = _playlist, numSongsNotAddedYet = _numSongsNotAddedYet;
static BOOL PRODUCTION_MODE;

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

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

    _numSongsNotAddedYet = (int)([Song loadAll].count - _playlist.songsInThisPlaylist.count);
    _lastTableViewModelCount = (int)_playlist.songsInThisPlaylist.count;
    
    if(_numSongsNotAddedYet == 0)
        _addBarButton.enabled = NO;
    
    //set song/album details for currently selected song
    NSString *navBarTitle = _playlist.playlistName;
    self.navBar.title = navBarTitle;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setProductionModeValue];
    [self setUpNavBarItems];
}

- (void)setUpNavBarItems
{
    UIBarButtonItem *editButton = self.editButtonItem;
    UIBarButtonItem *addButton = self.addBarButton;
    
    NSArray *rightBarButtonItems = [NSArray arrayWithObjects:editButton, addButton, nil];
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;  //place both buttons on the nav bar
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
    return _playlist.songsInThisPlaylist.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"playlistSongItemCell" forIndexPath:indexPath];
    
    // Configure the cell...
    Song *song = [_playlist.songsInThisPlaylist objectAtIndex: indexPath.row];  //get song object at this index
    
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
    //could also selectively choose which rows may be deleted here.
    if(_lastTableViewModelCount == 0)
        return NO;
    else
        return YES;
}

//editing the tableView items
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){  //user tapped delete on a row
        //delete song from the tableview data source
        [_playlist.songsInThisPlaylist removeObjectAtIndex:indexPath.row];
        
        //update the playlist object from our data model (which is saved to disk).
        [_playlist updateExistingPlaylist];
        
        //delete row from tableView (just the gui)
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        _numSongsNotAddedYet++;
        _lastTableViewModelCount--;
        
        if(_numSongsNotAddedYet == 0)
            _addBarButton.enabled = NO;
        else
            _addBarButton.enabled = YES;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    [self performSegueWithIdentifier:@"playlistSongItemPlayingSegue" sender:[NSNumber numberWithInt:(int)indexPath.row]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //song was tapped
    if([[segue identifier] isEqualToString: @"playlistSongItemPlayingSegue"]){
        int row = [(NSNumber *)sender intValue];
        
        //retrieve the song objects
        Song *selectedSong = [_playlist.songsInThisPlaylist objectAtIndex:row];
        Album *selectedAlbum = selectedSong.album;
        Artist *selectedArtist = selectedSong.artist;
        Playlist *selectedPlaylist;
        
        //setup properties in SongItemViewController.h
        [[segue destinationViewController] setANewSong:selectedSong];
        [[segue destinationViewController] setANewAlbum:selectedAlbum];
        [[segue destinationViewController] setANewArtist:selectedArtist];
        [[segue destinationViewController] setANewPlaylist:selectedPlaylist];
        
        int songNumber = row + 1;  //remember, for loop started at 0!
        if(songNumber < 0 || songNumber == 0)  //object not found in song model
            songNumber = -1;
        [[segue destinationViewController]setSongNumberInSongCollection:songNumber];
        [[segue destinationViewController]setTotalSongsInCollection:(int)_playlist.songsInThisPlaylist.count];
    }
}

- (IBAction)addButtonPressed:(id)sender
{
    //get ready to hand off the playlist object to the song picker
    [_playlist saveTempPlaylistOnDisk];
    
    //start listening for notifications (so we know when the modal song picker dissapears)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songPickerWasDismissed:) name:@"song picker dismissed" object:nil];
    
    //now segue to modal view where user can pick songs for this playlist
    [self performSegueWithIdentifier:@"addMoreSongsToPlaylist" sender:self];
}

- (void)songPickerWasDismissed:(NSNotification *)someNSNotification
{
    if([someNSNotification.name isEqualToString:@"song picker dismissed"]){
        NSArray *allPlaylists = [Playlist loadAll];
        //Update variable for model, if it changed...remember, playlists are only compared by name
        _playlist = [allPlaylists objectAtIndex:[allPlaylists indexOfObject:_playlist]];
        
        [self.tableView reloadData];
        
        if(_lastTableViewModelCount < _playlist.songsInThisPlaylist.count){  //songs added
            int x = (int)(_playlist.songsInThisPlaylist.count - _lastTableViewModelCount);
            _numSongsNotAddedYet = _numSongsNotAddedYet - x;
            _lastTableViewModelCount = _lastTableViewModelCount + x;
        }//else nothing changed (remember, we can't remove songs from the song picker)
        
        if(_numSongsNotAddedYet == 0)
            _addBarButton.enabled = NO;
        else
            _addBarButton.enabled = YES;
    }
}

@end
