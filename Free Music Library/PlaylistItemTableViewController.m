//
//  PlaylistItemTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/27/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlaylistItemTableViewController.h"

@implementation PlaylistItemTableViewController
@synthesize playlist = _playlist;
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
    return _playlist.songsInThisPlaylist.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SongItemCell" forIndexPath:indexPath];
    
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
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //song was tapped
    if([[segue identifier] isEqualToString: @"stuff"]){
        
    }
    //settings button tapped from side bar
    else if([[segue identifier] isEqualToString: @"settingsSegue"]){
        //do i need this?
    }
}

- (void)sidebar:(RNFrostedSidebar *)sidebar didTapItemAtIndex:(NSUInteger)index
{
    if (1){
        [sidebar dismissAnimated:YES];
        /**
         //push settings view controller on top of navigation controller!
         UIViewController *vCtrler = [self.storyboard instantiateViewControllerWithIdentifier:@"Settings"];
         [self.navigationController pushViewController:vCtrler animated:YES];
         */
    }
}

//called when + sign is tapped - selector defined in setUpNavBarItems method!
- (void)addButtonPressed
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"'+' Tapped"
                                                    message:@"This is how you add more songs to this playlist"
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
}

@end
