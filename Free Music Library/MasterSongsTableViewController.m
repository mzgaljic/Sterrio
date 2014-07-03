//
//  MasterSongsTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterSongsTableViewController.h"

@interface MasterSongsTableViewController ()
@property(nonatomic, strong) NSMutableArray *allSongsInLibrary;
@end

@implementation MasterSongsTableViewController
@synthesize allSongsInLibrary;
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
    
    //init tableView model
    self.allSongsInLibrary = [NSMutableArray arrayWithArray:[Song loadAll]];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setProductionModeValue];
    [self setUpNavBarItems];
}

- (void)setUpNavBarItems
{
    //edit button
    UIBarButtonItem *editButton = self.editButtonItem;
    
    //+ sign...also wire it up to the ibAction "addButtonPressed"
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                  target:self action:@selector(addButtonPressed)];
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
    return self.allSongsInLibrary.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SongItemCell" forIndexPath:indexPath];
    
    // Configure the cell...
    Song *song = [self.allSongsInLibrary objectAtIndex: indexPath.row];  //get song object at this index
   
    //init cell fields
    cell.textLabel.text = song.songName;
    NSString *detailStringLabel = [NSString stringWithFormat:@"%@-%@", song.artist.artistName, song.album.albumName];
    cell.detailTextLabel.text = detailStringLabel;
    
    if(! cell.imageView.image){  //image not already set
        if(PRODUCTION_MODE)
            cell.imageView.image = [AlbumArtUtilities albumArtFileNameToUiImage: song.albumArtFileName];
        else
            cell.imageView.image = [UIImage imageNamed:song.album.albumName];
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    //could also selectively choose which rows may be deleted here.
    return YES;
}

//editing the tableView items
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){  //user tapped delete on a row
        //obtain object for the deleted album
        Song *song = [self.allSongsInLibrary objectAtIndex:indexPath.row];
        
        //delete the object from our data model (which is saved to disk).
        [song deleteSong];
        
        //delete song from the tableview data source
        [[self allSongsInLibrary] removeObjectAtIndex:indexPath.row];
        
        //delete row from tableView (just the gui)
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //get the index of the tapped song
    UITableView *tableView = self.tableView;
    for(int i = 0; i < self.allSongsInLibrary.count; i++){
        UITableViewCell *cell =[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if(cell.selected){
            self.selectedRowIndexValue = i;
            break;
        }
    }
    
    //retrieve the song objects
    Song *selectedSong = [self.allSongsInLibrary objectAtIndex:self.selectedRowIndexValue];
    Album *selectedAlbum = selectedSong.album;
    Artist *selectedArtist = selectedSong.artist;
    Playlist *selectedPlaylist;
    
    //setup properties in SongItemViewController.h
    if([[segue identifier] isEqualToString: @"songItemSegue"]){
        [[segue destinationViewController] setANewSong:selectedSong];
        [[segue destinationViewController] setANewAlbum:selectedAlbum];
        [[segue destinationViewController] setANewArtist:selectedArtist];
        [[segue destinationViewController] setANewPlaylist:selectedPlaylist];
        
        int songNumber = self.selectedRowIndexValue + 1;  //remember, for loop started at 0!
        if(songNumber < 0 || songNumber == 0)  //object not found in song model
            songNumber = -1;
        [[segue destinationViewController] setSongNumberInSongCollection:songNumber];
        [[segue destinationViewController] setTotalSongsInCollection:(int)self.allSongsInLibrary.count];
    }
}

//called when + sign is tapped - selector defined in editSongsMode method!
- (void)addButtonPressed
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"'+' Tapped"
                                                    message:@"This is how you add music to the library!  :)"
                                                   delegate:nil
                                          cancelButtonTitle:@"Got it"
                                          otherButtonTitles:nil];
    [alert show];
}

- (IBAction)expandableMenuSelected:(id)sender
{
    //frosted side bar library code here? look in safari bookmarks!
    NSArray *images = @[
                        [UIImage imageNamed:@"playlists"],
                        [UIImage imageNamed:@"artists"], [UIImage imageNamed:@"genres"],
                        [UIImage imageNamed:@"songs"]];
    
    RNFrostedSidebar *callout = [[RNFrostedSidebar alloc] initWithImages:images];
    callout.delegate = self;
    [callout show];
    
    /**
    //temp code...
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Expanded Options"
                                                    message:@"Side bar with options should happen now."
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
     */
}
@end
