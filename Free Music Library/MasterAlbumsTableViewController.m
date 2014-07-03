//
//  MasterAlbumsTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterAlbumsTableViewController.h"

@interface MasterAlbumsTableViewController()
@property (nonatomic, strong) NSMutableArray *albums;
@end

@implementation MasterAlbumsTableViewController
@synthesize albums;
static BOOL PRODUCTION_MODE;

- (NSMutableArray *) results  //for searching tableview?
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
    self.albums = [NSMutableArray arrayWithArray:[Album loadAll]];
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
    return self.albums.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlbumItemCell" forIndexPath:indexPath];
    // Configure the cell...
    
    Album *album = [self.albums objectAtIndex: indexPath.row];  //get album instance at this index
    
    //init cell fields
    cell.textLabel.text = album.albumName;
    cell.detailTextLabel.text = album.artist.artistName;
    
    //could only update images for the cells that changed if i want to make this more efficient
    if(PRODUCTION_MODE)
        cell.imageView.image = [AlbumArtUtilities albumArtFileNameToUiImage: album.albumArtFileName];
    else
        cell.imageView.image = [UIImage imageNamed:album.albumName];
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
        Album *album = [self.albums objectAtIndex:indexPath.row];
        
        //delete the object from our data model (which is saved to disk).
        [album deleteAlbum];
        
        //delete album from the tableview data source
        [[self albums] removeObjectAtIndex:indexPath.row];
        
        //delete row from tableView (just the gui)
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //get the index of the tapped album
    UITableView *tableView = self.tableView;
    for(int i = 0; i < self.albums.count; i++){
        UITableViewCell *cell =[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if(cell.selected){
            self.selectedRowIndexValue = i;
            break;
        }
    }
    
    if([[segue identifier] isEqualToString: @"albumItemSegue"]){
        [[segue destinationViewController] setAlbum:self.albums[self.selectedRowIndexValue]];
    }
}

//called when + sign is tapped - selector defined in editSongsMode method!
- (void)addButtonPressed
{
    /**
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"'+' Tapped"
                                                    message:@"This is how you add songs to the library!  :)"
                                                   delegate:nil
                                          cancelButtonTitle:@"Got it"
                                          otherButtonTitles:nil];
    [alert show];
     */
    
    NSArray *indexes = @[[NSIndexPath indexPathWithIndex:3]];
    [self.tableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationFade];
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
}

@end