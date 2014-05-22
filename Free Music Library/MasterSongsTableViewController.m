//
//  MasterSongsTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterSongsTableViewController.h"
#import "SongItemViewController.h"

@interface MasterSongsTableViewController ()

@end

@implementation MasterSongsTableViewController

- (NSMutableArray *) songItemsArray
{
    if(! _songItemsArray){
        _songItemsArray = [[NSMutableArray alloc] init];
    }
    return _songItemsArray;
}

- (NSMutableArray *) results
{
    if(! _results){
        _results = [[NSMutableArray alloc] init];
    }
    return _results;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //initialize TableView from memory (loading list w/ song names) - using fake names for now!
    [self.songItemsArray addObject:@"sample"];
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
    return self.songItemsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SongItemCell" forIndexPath:indexPath];
    self.selectedRowIndexValue = (int) [tableView indexPathForSelectedRow].row;  //used when passing data to SongItemViewController
    
    // Configure the cell...
    cell.textLabel.text = self.songItemsArray[indexPath.row];
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString: @"ShowAndPlaySongContents"]){        
        [[segue destinationViewController] setSongNumberInSongCollection: self.selectedRowIndexValue];
        [[segue destinationViewController] setTotalSongsInCollection: (int) _songItemsArray.count];
        [[segue destinationViewController] setSongLabelValue:@"some Song"];
        [[segue destinationViewController] setArtist_AlbumLabelValue:@"an Artist - some Album"];
    }
}

@end
