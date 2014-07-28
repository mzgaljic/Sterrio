//
//  PlaylistItemTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/27/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlaylistItemTableViewController.h"

@interface PlaylistItemTableViewController()
@property (nonatomic, assign) int lastTableViewModelCount;
@property (nonatomic, strong) UITextField *txtField;
@end

@implementation PlaylistItemTableViewController
@synthesize playlist = _playlist, numSongsNotAddedYet = _numSongsNotAddedYet, txtField = _txtField;
static BOOL PRODUCTION_MODE;

- (void) dealloc
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

    _numSongsNotAddedYet = (int)([Song loadAll].count - _playlist.songsInThisPlaylist.count);
    _lastTableViewModelCount = (int)_playlist.songsInThisPlaylist.count;
    
    if(_numSongsNotAddedYet == 0)
        _addBarButton.enabled = NO;
    
    //set song/album details for currently selected song
    NSString *navBarTitle = _playlist.playlistName;
    self.navBar.title = navBarTitle;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self setProductionModeValue];
    [self setUpNavBarItems];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = NO;
}

- (void)setUpNavBarItems
{
    UIBarButtonItem *editButton = self.editButtonItem;
    editButton.action = @selector(editTapped:);
    UIBarButtonItem *addButton = self.addBarButton;
    
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
    return _playlist.songsInThisPlaylist.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"playlistSongItemCell" forIndexPath:indexPath];
    
    // Configure the cell...
    Song *song = [_playlist.songsInThisPlaylist objectAtIndex: indexPath.row];  //get song object at this index
    
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
    //could also selectively choose which rows may be deleted here.
    if(_lastTableViewModelCount == 0)
        return NO;
    else
        return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [SongTableViewFormatter preferredSongCellHeight];
}

//editing the tableView items
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){  //user tapped delete on a row
        //delete song from the tableview data source
        [_playlist.songsInThisPlaylist removeObjectAtIndex:indexPath.row];
        
        //update the playlist object from our data model (which is saved to disk).
        [_playlist updateExistingPlaylist];
        
        //delete row from tableView (just the gui)
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        _numSongsNotAddedYet++;
        _lastTableViewModelCount--;
        
        if(_numSongsNotAddedYet == 0)
            _addBarButton.enabled = NO;
        else
            _addBarButton.enabled = YES;
    }
}

- (void)editTapped:(id)sender
{
    if(self.editing)
    {
        [self.navBar setRightBarButtonItems:_originalRightBarButtonItems animated:YES];
        [self.navBar setLeftBarButtonItems:_originalLeftBarButtonItems animated:YES];
        [self.navigationItem setHidesBackButton:NO animated:YES];
        self.navBar.titleView = nil;
        self.navBar.title = _playlist.playlistName;
        _originalLeftBarButtonItems = nil;
        _originalRightBarButtonItems = nil;
        
        [super setEditing:NO animated:YES];
    }
    else
    {
        [super setEditing:YES animated:YES];
        
        //allows for renaming the playlist
        [self setUpUITextField];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    Song *item = [_playlist.songsInThisPlaylist objectAtIndex:fromIndexPath.row];
    [_playlist.songsInThisPlaylist removeObject:item];
    [_playlist.songsInThisPlaylist insertObject:item atIndex:toIndexPath.row];
    [_playlist updateExistingPlaylist];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    [self performSegueWithIdentifier:@"playlistSongItemPlayingSegue" sender:[NSNumber numberWithInt:(int)indexPath.row]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //song was tapped
    if([[segue identifier] isEqualToString: @"playlistSongItemPlayingSegue"]){
        int row = [(NSNumber *)sender intValue];
        
        //retrieve the song objects
        Song *selectedSong = [_playlist.songsInThisPlaylist objectAtIndex:row];
        Album *selectedAlbum = selectedSong.album;
        Artist *selectedArtist = selectedSong.artist;
        Playlist *selectedPlaylist;
        
        //setup properties in SongItemViewController.h
        [[segue destinationViewController] setANewSong:selectedSong];
        [[segue destinationViewController] setANewAlbum:selectedAlbum];
        [[segue destinationViewController] setANewArtist:selectedArtist];
        [[segue destinationViewController] setANewPlaylist:selectedPlaylist];
        
        int songNumber = row + 1;  //remember, for loop started at 0!
        if(songNumber < 0 || songNumber == 0)  //object not found in song model
            songNumber = -1;
        [[segue destinationViewController]setSongNumberInSongCollection:songNumber];
        [[segue destinationViewController]setTotalSongsInCollection:(int)_playlist.songsInThisPlaylist.count];
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

- (IBAction)addButtonPressed:(id)sender
{
    //get ready to hand off the playlist object to the song picker
    [_playlist saveTempPlaylistOnDisk];
    
    //start listening for notifications (so we know when the modal song picker dissapears)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songPickerWasDismissed:) name:@"song picker dismissed" object:nil];
    
    //now segue to modal view where user can pick songs for this playlist
    [self performSegueWithIdentifier:@"addMoreSongsToPlaylist" sender:self];
}

- (void)songPickerWasDismissed:(NSNotification *)someNSNotification
{
    if([someNSNotification.name isEqualToString:@"song picker dismissed"]){
        NSArray *allPlaylists = [Playlist loadAll];
        //Update variable for model, if it changed...remember, playlists are only compared by name
        _playlist = [allPlaylists objectAtIndex:[allPlaylists indexOfObject:_playlist]];
        
        [self.tableView reloadData];
        
        if(_lastTableViewModelCount < _playlist.songsInThisPlaylist.count){  //songs added
            int x = (int)(_playlist.songsInThisPlaylist.count - _lastTableViewModelCount);
            _numSongsNotAddedYet = _numSongsNotAddedYet - x;
            _lastTableViewModelCount = _lastTableViewModelCount + x;
        }//else nothing changed (remember, we can't remove songs from the song picker)
        
        if(_numSongsNotAddedYet == 0)
            _addBarButton.enabled = NO;
        else
            _addBarButton.enabled = YES;
    }
}

#pragma mark - UITextField methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *newName = textField.text;
    if([newName isEqualToString:_playlist.playlistName]){
        [textField resignFirstResponder];
        [self userTappedCancel];
        return YES;
    }
        
    NSArray *allPlaylists = [Playlist loadAll];
    BOOL duplicate = NO;
    for(Playlist *somePlaylist in allPlaylists){
        if([somePlaylist.playlistName isEqualToString:newName]){
            duplicate = YES;
            break;
        }
    }
    allPlaylists = nil;
    
    if(duplicate){
        //show uialertview with problem
        return NO;
    } else{
        [textField resignFirstResponder];
        [self commitNewPlaylistName:newName];
        return YES;
    }
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return YES;
}

- (void)setUpUITextField
{
    //so we can restore their state afterwards
    _originalLeftBarButtonItems = self.navBar.leftBarButtonItems;
    _originalRightBarButtonItems = self.navBar.rightBarButtonItems;
    
    _txtField = [[UITextField alloc] initWithFrame :CGRectMake(15, 100, 320, 30)];
    [_txtField addTarget:self action:@selector(userTappedUITextField) forControlEvents:UIControlEventEditingDidBegin];
    
    _txtField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _txtField.autoresizesSubviews = YES;
    _txtField.layer.cornerRadius = 5.0;
    [_txtField setBorderStyle:UITextBorderStyleRoundedRect];
    _txtField.text = _playlist.playlistName;
    if([AppEnvironmentConstants boldNames])
        _txtField.font = [UIFont boldSystemFontOfSize:20];
    else
        _txtField.font = [UIFont systemFontOfSize:20];
    //_txtField.returnKeyType = UIReturnKeyDone;  better if it looks like we're not leaving editing mode when return is hit
    _txtField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    _txtField.backgroundColor = [UIColor whiteColor];
    [[[[[_txtField.backgroundColor darkerColor] darkerColor]darkerColor] darkerColor] darkerColor];
    _txtField.textColor = [UIColor blackColor];
    [_txtField setDelegate:self];
    
    UIBarButtonItem *editButton = self.editButtonItem;
    editButton.action = @selector(editTapped:);
    
    [self.navigationItem setHidesBackButton:YES animated:NO];
    [self.navBar setRightBarButtonItems:@[editButton] animated:YES];
    [self.navBar setLeftBarButtonItems:nil animated:YES];
    self.navBar.titleView = _txtField;  //works?
}

- (void)userTappedCancel
{
    UIBarButtonItem *editButton = self.editButtonItem;
    editButton.action = @selector(editTapped:);
    [self.navBar setRightBarButtonItem:editButton animated:YES];
    _txtField.text = _playlist.playlistName;  //restore original playlist name
    
    [_txtField resignFirstResponder];
}

- (void)commitNewPlaylistName:(NSString *)newName
{
    [_playlist saveUnderNewName:newName];
    
    [self userTappedCancel];
}

- (void)userTappedUITextField
{
    [self.navBar setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                     target:self action:@selector(userTappedCancel)] animated:YES];
}


#pragma mark - Rotation status bar methods
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // only iOS 7 methods, check http://stackoverflow.com/questions/18525778/status-bar-still-showing
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }else {
        // iOS 6 code only here...checking if we are now going into landscape mode
        if((toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||(toInterfaceOrientation == UIInterfaceOrientationLandscapeRight))
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        else
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    }
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (BOOL)prefersStatusBarHidden
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
        return YES;
    else
        return NO;  //returned when in portrait, or when app is first launching (UIInterfaceOrientationUnknown)
}


@end
