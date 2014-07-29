//
//  PlaylistSongItemTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/13/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlaylistSongItemTableViewController.h"
#define Done_String @"Done"
#define AddLater_String @"Add later"
#define Cancel_String @"Cancel"

@interface PlaylistSongItemTableViewController()
@property (nonatomic, strong) NSMutableArray *allSongs;
@end

@implementation PlaylistSongItemTableViewController
@synthesize songsSelected = _songsSelected, receiverPlaylist = _receiverPlaylist, allSongs = _allSongs;
static BOOL PRODUCTION_MODE;
//playlist status codes
static const short IN_CREATION = 0;
static const short CREATED_BUT_EMPTY = 1;
static const short NORMAL_PLAYLIST = -1;

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
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight
       || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        self.tabBarController.tabBar.hidden = YES;
    }
    else
        self.tabBarController.tabBar.hidden = NO;
    
    _songsSelected = [NSMutableArray array];
    
    //init tableView model
    _receiverPlaylist = [Playlist loadTempPlaylistFromDisk];
    _allSongs = [NSMutableArray arrayWithArray:[Song loadAll]];
    
    if(_receiverPlaylist.status == IN_CREATION){  //creating new playlist
        self.rightBarButton.title = AddLater_String;
    } else if(_receiverPlaylist.status == NORMAL_PLAYLIST){  //adding songs to existing playlist
        [_allSongs removeObjectsInArray:_receiverPlaylist.songsInThisPlaylist];
        self.rightBarButton.title = @"";
    } else if(_receiverPlaylist.status == CREATED_BUT_EMPTY){  //possibly adding songs to existing playlist
        self.rightBarButton.title = @"";
        [_allSongs removeObjectsInArray:_receiverPlaylist.songsInThisPlaylist];
    }
    
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self setProductionModeValue];
    self.tableView.allowsMultipleSelection = YES;
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
    return _allSongs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"playlistSongItemPickerCell" forIndexPath:indexPath];
    
    [cell setAccessoryType:UITableViewCellAccessoryNone];
    for(int i = 0; i < _songsSelected.count; i++){
        NSUInteger num = [[_songsSelected objectAtIndex:i] intValue];
        if(num == indexPath.row){
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            break;  //found the match
        }
    }
    
    // Configure the cell...
    Song *song = [_allSongs objectAtIndex:indexPath.row];  //get song object at this index
    
    //init cell fields
    cell.textLabel.attributedText = [SongTableViewFormatter formatSongLabelUsingSong:song];
    if(! [SongTableViewFormatter songNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[SongTableViewFormatter nonBoldSongLabelFontSize]];
    [SongTableViewFormatter formatSongDetailLabelUsingSong:song andCell:&cell];
    
    UIImage *image;
    if(PRODUCTION_MODE)
        image = [AlbumArtUtilities albumArtFileNameToUiImage: song.albumArtFileName];
    else
        image = [UIImage imageNamed:song.album.albumName];
    
    image = [AlbumArtUtilities imageWithImage:image scaledToSize:[SongTableViewFormatter preferredSongAlbumArtSize]];
    cell.imageView.image = image;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    if([selectedCell accessoryType] == UITableViewCellAccessoryNone){  //selected row
        if(_songsSelected.count == 0){
             self.rightBarButton.title = Done_String;
            [self.rightBarButton setStyle:UIBarButtonItemStyleDone];
        }
        [selectedCell setAccessoryType:UITableViewCellAccessoryCheckmark];
        [_songsSelected addObject:[NSNumber numberWithInt:(int)indexPath.row]];
        
    } else{  //deselected row
        if(_songsSelected.count == 1 && _receiverPlaylist.status == IN_CREATION)
            self.rightBarButton.title = AddLater_String;  //only happens when playlist created from scratch
        
        else if(_songsSelected.count == 1 && _receiverPlaylist.status == CREATED_BUT_EMPTY)
            self.rightBarButton.title = @"";
        
        else if(_songsSelected.count == 1 && _receiverPlaylist.status == NORMAL_PLAYLIST)
            self.rightBarButton.title = @"";
        
        [selectedCell setAccessoryType:UITableViewCellAccessoryNone];
        [_songsSelected removeObject:[NSNumber numberWithInt:(int)indexPath.row]];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [SongTableViewFormatter preferredSongCellHeight];
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

- (IBAction)rightBarButtonTapped:(id)sender
{
    NSString *title = self.rightBarButton.title;
    if([title isEqualToString:Done_String]){
        _receiverPlaylist.status = NORMAL_PLAYLIST;
        
        //add all selected songs to the playlists songs array (the model on disk), "pop" modal view
        for(NSNumber *someIndex in _songsSelected){
            [_receiverPlaylist.songsInThisPlaylist addObject:[_allSongs objectAtIndex:[someIndex intValue]]];
        }
        
        [Playlist reInsertTempPlaylist:_receiverPlaylist];
        [self dismissViewControllerAnimated:YES completion:nil];
        
    } else if([title isEqualToString:AddLater_String]){
        //leave playlist empty and "pop" this modal view off the screen
        _receiverPlaylist.status = CREATED_BUT_EMPTY;
        [Playlist reInsertTempPlaylist:_receiverPlaylist];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    //must be at end, since the playlist needs to be reinserted into the model first.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"song picker dismissed" object:self];
}

- (IBAction)leftBarButtonTapped:(id)sender
{
    NSString *title = self.leftBarButton.title;
    if([title isEqualToString:Cancel_String] && _receiverPlaylist.status == CREATED_BUT_EMPTY){
        //cancel adding songs to this playlist, and "pop" this modal view off the screen.
        [Playlist reInsertTempPlaylist:_receiverPlaylist];  //deletes the temp playlist on disk
        [self dismissViewControllerAnimated:YES completion:nil];
        
    } else if([title isEqualToString:Cancel_String] && _receiverPlaylist.status == IN_CREATION){
        //cancel the creation of the playlist and "pop" this modal view off the screen.
        [_receiverPlaylist deletePlaylist];
        [Playlist reInsertTempPlaylist:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if([title isEqualToString:Cancel_String] && _receiverPlaylist.status == NORMAL_PLAYLIST){
        //don't add the checked songs to the playlist, and "pop" this modal view off the screen.
        [Playlist reInsertTempPlaylist:_receiverPlaylist];  //deletes the temp playlist on disk
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
