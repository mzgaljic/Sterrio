//
//  MasterAlbumsTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterAlbumsTableViewController.h"
#import "AlbumItemViewController.h"
#import "Album.h"

@implementation MasterAlbumsTableViewController
@synthesize albums;

- (NSMutableArray *) results  //for searching tableview?
{
    if(! _results){
        _results = [[NSMutableArray alloc] init];
    }
    return _results;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.albums = [Album loadAll];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SongItemCell" forIndexPath:indexPath];
    // Configure the cell...

    Album *album = [self.albums objectAtIndex: indexPath.row];  //get album at this index
    
    //init cell fields
    cell.textLabel.text = album.albumName;
    cell.detailTextLabel.text = album.artist.artistName;
    cell.imageView.image = [self albumArtFileNameToUiImage: album.albumArtFileName];
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString: @"AlbumItemSegue"]){
          //[[segue destinationViewController] setSongLabelValue:@"some Song"];
    }
}

- (UIImage *)albumArtFileNameToUiImage:(NSString *)albumArtFileName
{
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                    NSUserDomainMask, YES) objectAtIndex:0];
    NSString* path = [docDir stringByAppendingPathComponent: albumArtFileName];
    return [UIImage imageWithContentsOfFile:path];
}

@end
