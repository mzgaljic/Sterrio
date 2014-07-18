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

-(void)dealloc
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
    
    //init tableView model
    self.allSongsInLibrary = [NSMutableArray arrayWithArray:[Song loadAll]];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setProductionModeValue];
    [self setUpNavBarItems];
    self.tableView.allowsSelectionDuringEditing = YES;
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
    cell.textLabel.font = cell.detailTextLabel.font = [UIFont systemFontOfSize:19.0];
    //cell.textLabel.attributedText = [self BoldAttributedStringWithString:song.songName withFontSize:17.0];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:15.0];
    cell.detailTextLabel.attributedText = [self generateDetailLabelAttrStringWithArtistName:song.artist.artistName andAlbumName:song.album.albumName];
    
    UIImage *image;
    if(PRODUCTION_MODE)
        image = [AlbumArtUtilities albumArtFileNameToUiImage: song.albumArtFileName];
    else
        image = [UIImage imageNamed:song.album.albumName];
    
    image = [AlbumArtUtilities imageWithImage:image scaledToSize:CGSizeMake(55, 55)];
    cell.imageView.image = image;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    //could also selectively choose which rows may be deleted here.
    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65.0;
}

//editing the tableView items
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){  //user tapped delete on a row
        //obtain object for the deleted song
        Song *song = [self.allSongsInLibrary objectAtIndex:indexPath.row];
        
        //delete the object from our data model (which is saved to disk).
        [song deleteSong];
        
        //delete song from the tableview data source
        [[self allSongsInLibrary] removeObjectAtIndex:indexPath.row];
        
        //delete row from tableView (just the gui)
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    //get song for the tapped row
    self.selectedRowIndexValue = (int)indexPath.row;
    UIBarButtonItem *editButton = self.navigationItem.rightBarButtonItem;
    
    if([editButton.title isEqualToString:@"Edit"]){  //tapping song plays the song
        [self performSegueWithIdentifier:@"songItemSegue" sender:self];
        
    } else if([editButton.title isEqualToString:@"Done"]){  //tapping song triggers edit segue
        //send song object via NSNotificationCenter
        
        //now segue to modal view where user can edit the tapped song
        [self performSegueWithIdentifier:@"editingSongMasterSegue" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //song was tapped
    if([[segue identifier] isEqualToString: @"songItemSegue"]){
        //retrieve the song objects
        Song *selectedSong = [self.allSongsInLibrary objectAtIndex:self.selectedRowIndexValue];
        Album *selectedAlbum = selectedSong.album;
        Artist *selectedArtist = selectedSong.artist;
        Playlist *selectedPlaylist;
        
        //setup properties in SongItemViewController.h
        [[segue destinationViewController] setANewSong:selectedSong];
        [[segue destinationViewController] setANewAlbum:selectedAlbum];
        [[segue destinationViewController] setANewArtist:selectedArtist];
        [[segue destinationViewController] setANewPlaylist:selectedPlaylist];
        
        int songNumber = self.selectedRowIndexValue + 1;  //remember, for loop started at 0!
        if(songNumber < 0 || songNumber == 0)  //object not found in song model
            songNumber = -1;
        [[segue destinationViewController] setSongNumberInSongCollection:songNumber];
        [[segue destinationViewController] setTotalSongsInCollection:(int)self.allSongsInLibrary.count];
    } else if([[segue identifier] isEqualToString:@"editingSongMasterSegue"]){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingModeCompleted:) name:@"SongEditDone" object:nil];
        
        //set the songIAmEditing property in the modal view controller
        MasterEditingSongTableViewController* controller = (MasterEditingSongTableViewController*)[[segue destinationViewController] topViewController];
        [controller setSongIAmEditing:[self.allSongsInLibrary objectAtIndex:self.selectedRowIndexValue]];
    }
    else if([[segue identifier] isEqualToString: @"settingsSegue"]){  //settings button tapped from side bar
        //do i need this?
    }
}

- (void)editingModeCompleted:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"SongEditDone"]){
        //leave editing mode
        [self setEditing:NO animated:NO];
    }
}

- (NSAttributedString *)BoldAttributedStringWithString:(NSString *)aString withFontSize:(float)fontSize
{
    if(! aString)
        return nil;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:aString];
    [attributedText addAttribute: NSFontAttributeName value:[UIFont boldSystemFontOfSize:fontSize] range:NSMakeRange(0, [aString length])];
    return attributedText;
}

//adds a space to the artist string, then it just changes the album string to grey.
- (NSAttributedString *)generateDetailLabelAttrStringWithArtistName:(NSString *)artistString andAlbumName:(NSString *)albumString
{
    if(artistString == nil || albumString == nil)
        return nil;
    NSMutableString *newArtistString = [NSMutableString stringWithString:artistString];
    [newArtistString appendString:@" "];
    
    NSMutableString *entireString = [NSMutableString stringWithString:newArtistString];
    [entireString appendString:albumString];
    
    NSArray *components = @[newArtistString, albumString];
    //NSRange untouchedRange = [entireString rangeOfString:[components objectAtIndex:0]];
    NSRange grayRange = [entireString rangeOfString:[components objectAtIndex:1]];
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:entireString];
    
    [attrString beginEditing];
    [attrString addAttribute: NSForegroundColorAttributeName
                       value:[UIColor grayColor]
                       range:grayRange];
    [attrString endEditing];
    return attrString;
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
                                                    message:@"This is how you add music to the library!  :)"
                                                   delegate:nil
                                          cancelButtonTitle:@"Got it"
                                          otherButtonTitles:nil];
    [alert show];
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
