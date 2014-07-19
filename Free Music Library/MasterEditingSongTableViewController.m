//
//  MasterEditingSongTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/17/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterEditingSongTableViewController.h"

@interface MasterEditingSongTableViewController ()

@end

@implementation MasterEditingSongTableViewController
@synthesize songIAmEditing = _songIAmEditing;
static BOOL PRODUCTION_MODE;

- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //force tableview to only show cells with content (hide the invisible stuff at the bottom of the table)
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    //change background color of tableview
    self.tableView.backgroundColor = [UIColor clearColor];
    self.parentViewController.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setProductionModeValue];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)  //rows for editing
        return 5;
    if(section == 1)
        return 0;
    if(section == 2)  //row to delete this song
        return 1;
    else
        return -1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if(indexPath.section == 0){
        cell = [tableView dequeueReusableCellWithIdentifier:@"editingSongCellItemDetail"];
        if (cell == nil)
            //right detail cell
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"editingSongCellItemDetail"];
        
        if(indexPath.row == 0){  //song name
            cell.textLabel.text = @"Song Name";
            cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:_songIAmEditing.songName];
            
        } else if(indexPath.row == 1){  //artist
            cell.textLabel.text = @"Artist";
            cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:_songIAmEditing.artist.artistName];
            
        } else if(indexPath.row == 2){  //Album
            cell.textLabel.text = @"Album";
            cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:_songIAmEditing.album.albumName];
            
        } else if(indexPath.row == 3){  //Album Art
            cell.textLabel.text = @"Album Art";
            UIImage *image;
            if(PRODUCTION_MODE)
                image = [AlbumArtUtilities albumArtFileNameToUiImage: _songIAmEditing.albumArtFileName];
            else
                image = [UIImage imageNamed:_songIAmEditing.album.albumName];
            image = [AlbumArtUtilities imageWithImage:image scaledToSize:CGSizeMake(60, 60)];
            cell.accessoryView = [[ UIImageView alloc ] initWithImage:image];
            cell.detailTextLabel.text = @"";
            
        } else if(indexPath.row == 4){  //Genre
            cell.textLabel.text = @"Genre";
            //int genreCode = _songIAmEditing.genreCode;
            //get genre name
            cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:@"genre name here"];
        } else
            return nil;
    }
    
    //section 1 is used for padding, has no content
    
    if(indexPath.section == 2){
        cell = [tableView dequeueReusableCellWithIdentifier:@"editingSongCellItemBasic"];
        if (cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"editingSongCellItemBasic"];
        
        if(indexPath.row == 0){  //Delete song text
            cell.textLabel.text = @"Delete Song";
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor = [UIColor redColor];
        }
    }

    return cell;
}

- (NSAttributedString *)makeAttrStringGrayUsingString:(NSString *)aString
{
    NSMutableAttributedString *something = [[NSMutableAttributedString alloc] initWithString:aString];
    [something beginEditing];
    [something addAttribute: NSForegroundColorAttributeName
                             value:[UIColor grayColor]
                             range:NSMakeRange(0, aString.length)];
    [something endEditing];
    return something;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    //could also selectively choose which rows may be deleted here.
    return NO;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @" ";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 3)
        return 66;
    else
        return 50.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    //segue to other areas
    
    if(indexPath.section == 2){
        if(indexPath.row == 0){
            [_songIAmEditing deleteSong];
            [self dismissViewControllerAnimated:YES completion:nil];
        } else
            return;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    /**
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
     */
}


- (IBAction)leftBarButtonTapped:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SongEditDone" object:_songIAmEditing];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)rightBarButtonTapped:(id)sender
{
    
}
@end
