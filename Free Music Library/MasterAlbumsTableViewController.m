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

@interface MasterAlbumsTableViewController ()
@property (nonatomic, strong) NSMutableArray *albums;
@end
@implementation MasterAlbumsTableViewController
@synthesize albums;

static const BOOL PRODUCTION_MODE = NO;

- (void)makeFakeTestAlbums
{
    Artist *artist1 = [[Artist alloc] init];
    artist1.artistName = @"Leona Lewis";
    
    Album *album1 = [[Album alloc] init];
    album1.albumName = @"Echo (Deluxe Version)";
    album1.artist = artist1;
    album1.albumArtFileName = @"Echo (Deluxe Version).png";
    [album1 saveAlbum];
    //-----------------
    Artist *artist2 = [[Artist alloc] init];
    artist2.artistName = @"Colbie Caillat";
    
    Album *album2 = [[Album alloc] init];
    album2.albumName = @"Hold On - Single";
    album2.artist = artist2;
    album2.albumArtFileName = @"Hold On - Single.png";
    [album2 saveAlbum];
    //-----------------
    Artist *artist3 = [[Artist alloc] init];
    artist3.artistName = @"Betty Who";
    
    Album *album3 = [[Album alloc] init];
    album3.albumName = @"The Movement - EP";
    album3.artist = artist3;
    album3.albumArtFileName = @"The Movement - EP.png";
    [album3 saveAlbum];
    //-----------------
    Artist *artist4 = [[Artist alloc] init];
    artist4.artistName = @"Lionel Richie";
    
    Album *album4 = [[Album alloc] init];
    album4.albumName = @"20th Century Masters - The Millennium Collection- The Best of Lionel Richie";
    album4.artist = artist4;
    album4.albumArtFileName = @"20th Century Masters - The Millennium Collection- The Best of Lionel Richie.png";
    [album4 saveAlbum];
    //-----------------
    Artist *artist5 = [[Artist alloc] init];
    artist4.artistName = @"The Cab";
    
    Album *album5 = [[Album alloc] init];
    album5.albumName = @"Whisper War";
    album5.artist = artist5;
    album5.albumArtFileName = @"Whisper War.png";
    [album5 saveAlbum];
    //-----------------
    Artist *artist6 = [[Artist alloc] init];
    artist6.artistName = @"Various Artists";
    
    Album *album6 = [[Album alloc] init];
    album6.albumName = @"Frozen (Original Motion Picture Soundtrack)";
    album6.artist = artist6;
    album6.albumArtFileName = @"Frozen (Original Motion Picture Soundtrack).png";
    [album6 saveAlbum];
    //-----------------
    Artist *artist7 = [[Artist alloc] init];
    artist7.artistName = @"Paper Route";
    
    Album *album7 = [[Album alloc] init];
    album7.albumName = @"You and I - Single";
    album7.artist = artist7;
    album7.albumArtFileName = @"You and I - Single.png";
    [album7 saveAlbum];
}


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
    
    self.albums = [NSMutableArray arrayWithArray:[Album loadAll]];
    if(self.albums.count == 0 && !PRODUCTION_MODE){
        [self makeFakeTestAlbums];
        self.albums = [NSMutableArray arrayWithArray:[Album loadAll]];
    }
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlbumItemCell" forIndexPath:indexPath];
    // Configure the cell...
    
    Album *album = [self.albums objectAtIndex: indexPath.row];  //get album instance at this index
    
    //init cell fields
    cell.textLabel.text = album.albumName;
    cell.detailTextLabel.text = album.artist.artistName;
    if(! cell.imageView.image)  //image not already set
        cell.imageView.image = [self albumArtFileNameToUiImage: album.albumArtFileName];
    
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
