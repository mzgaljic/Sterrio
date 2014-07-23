//
//  MasterPlaylistTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterPlaylistTableViewController.h"

@interface MasterPlaylistTableViewController ()
@property(nonatomic, strong) NSMutableArray *allPlaylists;
@property(nonatomic, strong) UIAlertView *createPlaylistAlert;
@end

@implementation MasterPlaylistTableViewController
@synthesize allPlaylists = _allPlaylists, createPlaylistAlert = _createPlaylistAlert;
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
    _allPlaylists = [NSMutableArray arrayWithArray:[Playlist loadAll]];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setProductionModeValue];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = NO;
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
    return _allPlaylists.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PlaylistItemCell" forIndexPath:indexPath];
    // Configure the cell...
    
    Playlist *playlist = [_allPlaylists objectAtIndex: indexPath.row];  //get playlist instance at this index
    
    //init cell fields
    cell.textLabel.attributedText = [PlaylistTableViewFormatter formatPlaylistLabelUsingPlaylist:playlist];
    if(! [PlaylistTableViewFormatter playlistNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[PlaylistTableViewFormatter nonBoldPlaylistLabelFontSize]];
    //playlist doesnt have detail label  :)
    
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
        //obtain object for the deleted playlist
        Playlist *playlist = [_allPlaylists objectAtIndex:indexPath.row];
        
        //delete the object from our data model (which is saved to disk).
        [playlist deletePlaylist];
        
        //delete album from the tableview data source
        [_allPlaylists removeObjectAtIndex:indexPath.row];
        
        //delete row from tableView (just the gui)
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    //now segue to push view where user can view the tapped playlist
   [self performSegueWithIdentifier:@"playlistItemSegue" sender:[_allPlaylists objectAtIndex:(int)indexPath.row]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PlaylistTableViewFormatter preferredPlaylistCellHeight];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{    
    if([[segue identifier] isEqualToString: @"playlistItemSegue"]){
        [[segue destinationViewController] setPlaylist:sender];
    }
}

- (IBAction)addButtonPressed:(id)sender
{
    _createPlaylistAlert = [[UIAlertView alloc] init];
    _createPlaylistAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    _createPlaylistAlert.title = @"New Playlist";
    [_createPlaylistAlert textFieldAtIndex:0].placeholder = @"Name your new playlist";
    _createPlaylistAlert.delegate = self;
    [_createPlaylistAlert addButtonWithTitle:@"Cancel"];
    [_createPlaylistAlert addButtonWithTitle:@"Create"];
    [_createPlaylistAlert show];

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView == _createPlaylistAlert){
        if(buttonIndex == 1){
            NSString *playlistName = [alertView textFieldAtIndex:0].text;
            if(playlistName.length == 0)
                return;
            int numSpaces = 0;
            for(int i = 0; i < playlistName.length; i++){
                if([playlistName characterAtIndex:i] == ' ')
                    numSpaces++;
            }
            if(numSpaces == playlistName.length){
                return;  //playlist can't be all whitespace.
            }
            
            //create the playlist
            Playlist *newPlaylist = [[Playlist alloc] init];
            newPlaylist.playlistName = playlistName;
            [newPlaylist saveTempPlaylistOnDisk];
            
            //now segue to modal view where user can pick songs for this playlist
            [self performSegueWithIdentifier:@"playlistSongItemPickerSegue" sender:self];
        }
        else  //canceled
            return;
    }
}

- (void)sidebar:(RNFrostedSidebar *)sidebar didTapItemAtIndex:(NSUInteger)index
{
    if (1){
        [sidebar dismissAnimated:YES];
        if(index == 3)  //settings button
            [self performSegueWithIdentifier:@"settingsSegue" sender:self];
    }
}

- (IBAction)expandableMenuSelected:(id)sender
{
    [FrostedSideBarHelper setupAndShowSlideOutMenuUsingdelegate:self];
}

@end
