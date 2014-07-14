//
//  MasterArtistsTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterArtistsTableViewController.h"

@interface MasterArtistsTableViewController ()
@property(nonatomic, strong) NSMutableArray *allArtists;
@end

@implementation MasterArtistsTableViewController
@synthesize allArtists = _allArtists;
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
    _allArtists = [NSMutableArray arrayWithArray:[Artist loadAll]];
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
    
    NSArray *rightBarButtonItems = [NSArray arrayWithObjects:editButton, nil];
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
    return self.allArtists.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ArtistItemCell" forIndexPath:indexPath];
    
    // Configure the cell...
    Artist *artist = [self.allArtists objectAtIndex: indexPath.row];  //get artist object at this index
    
    //init cell fields
    cell.textLabel.text = artist.artistName;
    
    int songsInAlbumsCount = 0;
    //count all the songs that are associated with albums for this artist
    for(int i = 0; i < artist.allAlbums.count; i++){
        Album *anAlbum = artist.allAlbums[i];
        for(int k = 0; k < anAlbum.albumSongs.count; k++){
            songsInAlbumsCount++;
        }
    }
    NSString *detailStringLabel = [NSString stringWithFormat:@"%d Albums, %d Songs", (int)artist.allAlbums.count, (int)artist.allSongs.count + songsInAlbumsCount];
    cell.detailTextLabel.text = detailStringLabel;
    
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
        //obtain object for the deleted artist
        Artist *artist = [self.allArtists objectAtIndex:indexPath.row];
        
        [[AlteredModelArtistQueue createSingleton] enqueue:[[AlteredModelItem alloc] initWithRemovedArtist:artist]];
        
        //delete the object from our data model (which is saved to disk).
        [artist deleteArtist];
        
        //delete artist from the tableview data source
        [[self allArtists] removeObjectAtIndex:indexPath.row];
        
        //delete row from tableView (just the gui)
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //get the index of the tapped artist
    UITableView *tableView = self.tableView;
    for(int i = 0; i < self.allArtists.count; i++){
        UITableViewCell *cell =[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if(cell.selected){
            self.selectedRowIndexValue = i;
            break;
        }
    }
    
    //retrieve the artist object
    Artist *selectedArtist = [self.allArtists objectAtIndex:self.selectedRowIndexValue];
    
    //setup properties in ArtistItemViewController.h
    if([[segue identifier] isEqualToString: @"artistItemSegue"]){
        [[segue destinationViewController] setArtist:selectedArtist];
        
        int artistNumber = self.selectedRowIndexValue + 1;  //remember, for loop started at 0!
        if(artistNumber < 0 || artistNumber == 0)  //object not found in artist model
            artistNumber = -1;
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
@end