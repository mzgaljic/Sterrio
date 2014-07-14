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
    return _allPlaylists.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PlaylistItemCell" forIndexPath:indexPath];
    // Configure the cell...
    
    Playlist *playlist = [_allPlaylists objectAtIndex: indexPath.row];  //get playlist instance at this index
    
    //init cell fields
    cell.textLabel.text = playlist.playlistName;
    
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //get the index of the tapped playlist
    UITableView *tableView = self.tableView;
    for(int i = 0; i < _allPlaylists.count; i++){
        UITableViewCell *cell =[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if(cell.selected){
            self.selectedRowIndexValue = i;
            break;
        }
    }
    
    if([[segue identifier] isEqualToString: @"playlistItemSegue"]){
        [[segue destinationViewController] setPlaylist:[_allPlaylists objectAtIndex:self.selectedRowIndexValue]];
    }
}

//called when + sign is tapped - selector defined in setUpNavBarItems method!
- (void)addButtonPressed
{
    _createPlaylistAlert = [[UIAlertView alloc] init];
    _createPlaylistAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    _createPlaylistAlert.message = @"Enter a name for your new playlist.";
    _createPlaylistAlert.delegate = self;
    [_createPlaylistAlert addButtonWithTitle:@"Cancel"];
    [_createPlaylistAlert addButtonWithTitle:@"Create"];
    
    [_createPlaylistAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView == _createPlaylistAlert){
        if(buttonIndex == 1){  //create playlist
            NSString *playlistName = [alertView textFieldAtIndex:0].text;
            if(playlistName.length == 0)
                return;
            int numSpaces = 0;
            for(int i = 0; i < playlistName.length; i++){
                if([playlistName characterAtIndex:i] == ' ')
                    numSpaces++;
            }
            if(numSpaces == playlistName.length)
                return;  //playlist can't be all whitespace.
            
            [self writeNewPlaylistNameToTempFile: playlistName];
            
            //now segue to modal view where user can pick songs for this playlist
            [self performSegueWithIdentifier:@"playlistSongItemPickerSegue" sender:self];
        }
        else  //canceled
            return;
    }
}

- (IBAction)expandableMenuSelected:(id)sender
{
    NSArray *images = @[[UIImage imageNamed:@"playlists"],[UIImage imageNamed:@"artists"],
                        [UIImage imageNamed:@"genres"],[UIImage imageNamed:@"songs"]];
    
    NSArray *colors =@[[UIColor blueColor],[UIColor redColor],[UIColor greenColor],[UIColor purpleColor]];
    
    NSRange range;
    range.length = 4;
    range.location = 0;
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
    
    RNFrostedSidebar *callout = [[RNFrostedSidebar alloc] initWithImages:images selectedIndices:indexSet borderColors:colors];
    callout.animationDuration = .3;
    callout.borderWidth = 1;
    callout.delegate = self;
    [callout show];

}

- (BOOL)writeNewPlaylistNameToTempFile:(NSString *)newPlaylistName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"temp file"];
    
    NSString *myString = newPlaylistName;
    return [myString writeToFile:dataPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end
