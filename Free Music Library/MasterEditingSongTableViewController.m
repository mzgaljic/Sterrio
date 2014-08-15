//
//  MasterEditingSongTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/17/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterEditingSongTableViewController.h"

@interface MasterEditingSongTableViewController ()
@property (nonatomic, strong) NSString *currentSongName;
@property (nonatomic, strong) Artist *currentArtist;
@property (nonatomic, strong) Album *currentAlbum;
@property (nonatomic, assign) int currentGenreCode;

@property (nonatomic, strong) UIImage *currentAlbumArt;
@property (nonatomic, strong) UIImage *currentSmallAlbumArt;
@end

@implementation MasterEditingSongTableViewController
@synthesize songIAmEditing = _songIAmEditing;
static BOOL PRODUCTION_MODE;
static int const HEIGHT_OF_ALBUM_ART_CELL = 66;

- (void)setCurrentAlbumArt:(UIImage *)currentAlbumArt
{
    if(currentAlbumArt == nil){
        _currentAlbumArt = nil;
        currentAlbumArt = nil;
        _currentSmallAlbumArt = nil;
        return;
    } else{
        _currentAlbumArt = currentAlbumArt;
        currentAlbumArt = nil;
        _currentSmallAlbumArt = [AlbumArtUtilities imageWithImage:_currentAlbumArt
                                                     scaledToSize:CGSizeMake(HEIGHT_OF_ALBUM_ART_CELL - 2, HEIGHT_OF_ALBUM_ART_CELL - 2)];
        return;
    }
}

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
    
    _currentSongName = _songIAmEditing.songName;
    _currentArtist = _songIAmEditing.artist;
    _currentAlbum = _songIAmEditing.album;
    _currentGenreCode = _songIAmEditing.genreCode;
    self.currentAlbumArt = [AlbumArtUtilities albumArtFileNameToUiImage:_songIAmEditing.albumArtFileName];
    
    //remove header gap at top of table, and remove some scrolling space under the delete button (update scroll insets too)
    [self.tableView setContentInset:UIEdgeInsetsMake(-32,0,-30,0)];
    [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(-32,0,-30,0)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(existingAlbumHasBeenChosen:)
                                                 name:@"existing album chosen" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(existingArtistHasBeenChosen:)
                                                 name:@"existing artist chosen" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newGenreHasBeenChosen:) name:@"new genre has been chosen" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = YES;
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"existing album chosen" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"existing artist chosen" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"new genre has been chosen" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)  //rows for editing
        return 5;
    if(section == 1)  //row to delete this song
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
            cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:_currentSongName];
            
        } else if(indexPath.row == 1){  //artist
            cell.textLabel.text = @"Artist";
            if(_currentArtist != nil)
                cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:_currentArtist.artistName];
            else
                cell.detailTextLabel.text = @"";
                
        } else if(indexPath.row == 2){  //Album
            cell.textLabel.text = @"Album";
            if(_currentAlbum != nil)
                cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:_currentAlbum.albumName];
            else
                cell.detailTextLabel.text = @"";
            
        } else if(indexPath.row == 3){  //Album Art
            cell.textLabel.text = @"Album Art";
            if(_currentSmallAlbumArt)
                cell.accessoryView = [[ UIImageView alloc ] initWithImage:_currentSmallAlbumArt];
            else
                cell.accessoryView = nil;
            cell.detailTextLabel.text = @"";
            
        } else if(indexPath.row == 4){  //Genre
            cell.textLabel.text = @"Genre";
            if(_currentGenreCode != [GenreConstants noGenreSelectedGenreCode]){
                NSString *genreString = [GenreConstants genreCodeToString:_currentGenreCode];
                cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:genreString];
            }
            else
                cell.detailTextLabel.text = @"";
        } else
            return nil;
    }
    if(indexPath.section == 1){
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
        return HEIGHT_OF_ALBUM_ART_CELL;
    else
        return 50.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    //segue to other areas
    if(indexPath.section == 0){
        switch (indexPath.row)
        {
            case 0:  //editing song name
            {
                _lastTappedRow = 0;
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songNameEditingComplete:)
                                                             name:@"DoneEditingSongField" object:nil];
                EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:_currentSongName
                                                                                              notificationNameToPost:@"DoneEditingSongField"];
                [self.navigationController pushViewController:vc animated:YES];
                break;
            }
            case 1:  //editing artist
            {
                UIActionSheet *popup;
                if(! _currentArtist){
                    popup = [[UIActionSheet alloc] initWithTitle:@"Artist" delegate:self cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:nil otherButtonTitles:@"Add to Existing Artist", @"Create New Artist", nil];
                } else if(_currentArtist){
                    popup = [[UIActionSheet alloc] initWithTitle:@"Artist" delegate:self cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:@"Remove From Artist" otherButtonTitles:@"Choose Different Artist", @"Create New Artist", nil];
                }
                
                popup.tag = 1;
                [popup showInView:self.navigationController.view];
                _lastTappedRow = 1;
                break;
            }
            case 2:  //editing album
            {
                if(_currentAlbum){
                    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Album" delegate:self cancelButtonTitle:@"Cancel"
                                                         destructiveButtonTitle:@"Remove Song From Album"
                                                              otherButtonTitles:@"Place In Different Album", @"Create New Album", nil];
                    popup.tag = 2;
                    [popup showInView:self.navigationController.view];
                    
                } else{
                    //album picker
                    
                    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Album" delegate:self cancelButtonTitle:@"Cancel"
                                                         destructiveButtonTitle:nil
                                                              otherButtonTitles:@"Place In Album", @"Create New Album", nil];
                    popup.tag = 2;
                    [popup showInView:self.navigationController.view];
                }
                _lastTappedRow = 2;
                break;
            }
            case 3:  //editing album art
            {//can only edit album art w/ a song that is part of an album IF you edit the album itself.
                if(! _currentAlbum.albumArtFileName)
                {
                    if(_currentAlbumArt)  //song already contains album art
                    {  //ask to remove art or add new art (photo or safari)
                        UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Album Art" delegate:self cancelButtonTitle:@"Cancel"
                                                             destructiveButtonTitle:@"Remove Album Art"
                                                                  otherButtonTitles:@"Choose Photo", @"Search for Art", nil];
                        popup.tag = 3;
                        [popup showInView:[self.navigationController view]];
                    }
                    else
                    {   //album art not picked yet, dont show option to remove album art
                        UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Album Art" delegate:self cancelButtonTitle:@"Cancel"
                                                             destructiveButtonTitle:nil
                                                                  otherButtonTitles:@"Choose Photo", @"Search for Art", nil];
                        popup.tag = 3;
                        [popup showInView:[self.navigationController view]];
                    }
                }
                else
                    //custom alertview, request that user edits album art in the album itself.
                    [self launchAlertViewWithDialog];
                
                _lastTappedRow = 3;
                break;
            }
            case 4://Genres
                if(_currentGenreCode == [GenreConstants noGenreSelectedGenreCode]){  //adding genre
                    GenrePickerTableViewController *vc = [[GenrePickerTableViewController alloc] initWithGenreCode:_currentGenreCode
                                                                                            notificationNameToPost:@"new genre has been chosen"];
                    [self.navigationController pushViewController:vc animated:YES];
                } else{  //option to remove genre or choose a different one
                    
                    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Genre" delegate:self cancelButtonTitle:@"Cancel"
                                                         destructiveButtonTitle:@"Remove Genre"
                                                              otherButtonTitles:@"Select Different Genre", nil];
                    popup.tag = 4;
                    [popup showInView:[self.navigationController view]];
                }
                
                _lastTappedRow = 4;
                break;
        }
    }
    
    if(indexPath.section == 1){
        if(indexPath.row == 0){
            //defensively check to see if the song we're about to delete is playing. if so, avoid a crash.
            if([_songIAmEditing isEqual:[PlaybackModelSingleton createSingleton].nowPlayingSong]){
                YouTubeMoviePlayerSingleton *singleton = [YouTubeMoviePlayerSingleton createSingleton];
                [[singleton AVPlayer] pause];
                [singleton setAVPlayerInstance:nil];
                [singleton setAVPlayerLayerInstance:nil];
            }
            
            [_songIAmEditing deleteSong];
            [self dismissViewControllerAnimated:YES completion:nil];
        } else
            return;
    }
}

#pragma mark - Editing text fields and creating new stuff
- (void)songNameEditingComplete:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DoneEditingSongField" object:nil];
    NSString *newName = (NSString *)notification.object;
    newName = [newName removeIrrelevantWhitespace];
    
    if([_currentSongName isEqualToString:newName])
        return;
    if(newName.length == 0)  //was all whitespace, or user gave us an empty string
        return;
    
    /**
    //changing song name in this case will break link between song and album art file. This is how i keep it in sync...
    if(! _songIAmEditing.associatedWithAlbum){
        if(_songIAmEditing.albumArtFileName){
            if([AlbumArtUtilities isAlbumArtAlreadySavedOnDisk:_songIAmEditing.albumArtFileName]){
                UIImage *albumArt = [AlbumArtUtilities albumArtFileNameToUiImage:_songIAmEditing.albumArtFileName];
                [_songIAmEditing removeAlbumArt];
                [_songIAmEditing setAlbumArt:nil];
                _songIAmEditing.songName = newName;
                
                //after song name is changed, NOW we can create the image file on disk, so it has the correct name.
                [_songIAmEditing setAlbumArt:albumArt];  //this creates the image file, names it, and saves it on disk.
            }
        }
    } else
        _songIAmEditing.songName = (NSString *)notification.object;
     */
    _currentSongName = newName;
    [self.tableView reloadData];
}

- (void)artistNameCreationCompleteAndSetUpArtist:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DoneEditingArtistField" object:nil];
    NSString *artistName = (NSString *)notification.object;
    artistName = [artistName removeIrrelevantWhitespace];
    
    //not checking for some album name because we CAN create albums with the same name!
    if(artistName.length == 0)  //was all whitespace, or user gave us an empty string
        return;
    Artist *artistWhichMayBeSavedLater = [[Artist alloc] init];
    artistWhichMayBeSavedLater.artistName = artistName;
    _currentArtist = artistWhichMayBeSavedLater;
    [self.tableView reloadData];
}

- (void)albumNameCreationCompleteAndSetUpAlbum:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DoneEditingAlbumField" object:nil];
    NSString *albumName = (NSString *)notification.object;
    albumName = [albumName removeIrrelevantWhitespace];
    
    //not checking for some album name because we CAN create albums with the same name!
    if(albumName.length == 0)  //was all whitespace, or user gave us an empty string
        return;
    Album *albumWhichMayBeSavedLater = [[Album alloc] init];
    albumWhichMayBeSavedLater.albumName = albumName;
    _currentAlbum = albumWhichMayBeSavedLater;
    [self.tableView reloadData];
}

#pragma mark - existing album and artist chosen
- (void)existingAlbumHasBeenChosen:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"existing album chosen"]){
        _currentAlbum = (Album *)notification.object;
        self.currentAlbumArt = [AlbumArtUtilities albumArtFileNameToUiImage:_currentAlbum.albumArtFileName];
        _currentArtist = _currentAlbum.artist;
        _currentGenreCode = _currentAlbum.genreCode;
        [self.tableView reloadData];
    }
}

- (void)existingArtistHasBeenChosen:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"existing artist chosen"]){
        _currentArtist = (Artist *)notification.object;
        _currentAlbum = nil;
        [self.tableView reloadData];
    }
}

- (void)newGenreHasBeenChosen:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"new genre has been chosen"]){
        NSString *genreName = (NSString *)notification.object;
        _currentGenreCode = [GenreConstants genreStringToCode:(NSString *)notification.object];
        [self.tableView reloadData];
    }
}

#pragma mark - nav bar buttons
- (IBAction)leftBarButtonTapped:(id)sender  //cancel
{
    //make sure album art file name is what it should be.
    
    //tell MasterSongsTableViewController that it should leave editing mode since song editing has completed.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SongEditDone" object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)rightBarButtonTapped:(id)sender  //save
{
    //if(){
        //commit song name changes to disk if necessary
    //}
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"SongSavedDuringEdit" object:_songIAmEditing];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SongEditDone" object:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIActionSheet methods
- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(popup.tag == 1){  //artist action sheet
        switch (buttonIndex)
        {
            case 0:
            {
                if(! _currentArtist){  //add song to an existing artist
                    ExistingArtistPickerTableViewController *vc = [[ExistingArtistPickerTableViewController alloc]
                                                                   initWithCurrentArtist:_currentArtist];
                    [self.navigationController pushViewController:vc animated:YES];
                } else if(_currentArtist){  //remove from current artist
                    _currentArtist = nil;
                    [self.tableView reloadData];
                }
            }
                break;
            case 1:
                if(! _currentArtist){
                    //create a new artist
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(artistNameCreationCompleteAndSetUpArtist:)
                                                                 name:@"DoneEditingArtistField" object:nil];
                    EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:nil
                                                                                                  notificationNameToPost:@"DoneEditingArtistField"];
                    [self.navigationController pushViewController:vc animated:YES];
                    
                } else if(_currentArtist){//choose different artist
                    ExistingArtistPickerTableViewController *vc = [[ExistingArtistPickerTableViewController alloc]
                                                                   initWithCurrentArtist:_currentArtist];
                    [self.navigationController pushViewController:vc animated:YES];
                }
                break;
            case 2:
            {
                if(_currentArtist){
                    //create new artist
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(artistNameCreationCompleteAndSetUpArtist:)
                                                                 name:@"DoneEditingArtistField" object:nil];
                    EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:nil
                                                                                                  notificationNameToPost:@"DoneEditingArtistField"];
                    [self.navigationController pushViewController:vc animated:YES];

                } else
                    break;
            }
            default:
                break;
        }
    } else if(popup.tag == 2){  //album action sheet
        switch (buttonIndex)
        {
            case 0:
                if(_currentAlbum){  //remove song from album (and reset some data)
                    _currentAlbum = nil;
                    [self.tableView reloadData];
                } else{ //choose existing album
                    ExistingAlbumPickerTableViewController *vc = [[ExistingAlbumPickerTableViewController alloc]
                                                                  initWithCurrentAlbum:_currentAlbum];
                    [self.navigationController pushViewController:vc animated:YES];
                }
                break;
            case 1:
                if(! _currentAlbum){  //create new album
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumNameCreationCompleteAndSetUpAlbum:)
                                                                 name:@"DoneEditingAlbumField" object:nil];
                    EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:nil
                                                                                                  notificationNameToPost:@"DoneEditingAlbumField"];
                    [self.navigationController pushViewController:vc animated:YES];
                    break;
                } else{  //place in different album (existing album picker)
                    ExistingAlbumPickerTableViewController *vc = [[ExistingAlbumPickerTableViewController alloc]
                                                                  initWithCurrentAlbum:_currentAlbum];
                    [self.navigationController pushViewController:vc animated:YES];
                }
                
                break;
            case 2:
                if(_currentAlbum){  //create new album
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumNameCreationCompleteAndSetUpAlbum:)
                                                                 name:@"DoneEditingAlbumField" object:nil];
                    EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:nil
                                                                                                  notificationNameToPost:@"DoneEditingAlbumField"];
                    [self.navigationController pushViewController:vc animated:YES];
                } else{
                    //remove song from album
                    _currentAlbum = nil;
                    [self.tableView reloadData];
                }
                break;
            default:
                break;
        }
    } else if(popup.tag == 3){  //album art (if this song isn't part of an album, otherwise a UIAlertView is displayed)
        switch (buttonIndex)
        {
        case 0:
                if(_currentAlbumArt)  //remove art
                    self.currentAlbumArt = nil;
                else  //chose photo from phone for art
                    [self pickNewAlbumArtFromPhotos];
                [self.tableView reloadData];
                break;
        case 1:
                if(! _currentAlbumArt){  //search for art
                    [self jumpToSafariToFindAlbumArt];
                } else{//chose photo
                    [self pickNewAlbumArtFromPhotos];
                }
                break;
        case 2: //search for art
                if(_currentAlbumArt)
                    [self jumpToSafariToFindAlbumArt];
                break;
        default:
                break;
        }
    } else if(popup.tag == 4){  //genre already present, providing option to remove genre or choose a different one
        switch (buttonIndex)
        {
            case 0:  //remove genre
                _currentGenreCode = [GenreConstants noGenreSelectedGenreCode];
                [self.tableView reloadData];
                break;
            case 1:  //find a different genre
            {
                GenrePickerTableViewController *vc = [[GenrePickerTableViewController alloc] initWithGenreCode:_currentGenreCode
                                                                                        notificationNameToPost:@"new genre has been chosen"];
                [self.navigationController pushViewController:vc animated:YES];
                break;
            }
            case 2:  //cancel
                break;
            default:
                break;
        }

    }
}

#pragma mark - Album Art Methods
- (void)pickNewAlbumArtFromPhotos
{
    UIImagePickerController *photoPickerController = [[UIImagePickerController alloc] init];
    photoPickerController.delegate = self;
    [self presentViewController:photoPickerController animated:YES completion:nil];
}

- (void)jumpToSafariToFindAlbumArt
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"x-web-search://?%@", [[self buildAlbumArtSearchString] stringForHTTPRequest]]];
    
    if (![[UIApplication sharedApplication] openURL:url])
        NSLog(@"%@%@",@"Failed to open url:",[url description]);
#warning display 'failed to open safari' warning to user
}

- (NSString *)buildAlbumArtSearchString
{
    NSMutableString *albumArtSearchTerm = [NSMutableString stringWithString:@""];
    if(_currentAlbum != nil)
        [albumArtSearchTerm appendString: _currentAlbum.albumName];
    [albumArtSearchTerm appendString:@" "];
    
    if(_currentArtist != nil)
        [albumArtSearchTerm appendString: _currentArtist.artistName];
    [albumArtSearchTerm appendString:@" "];
    
    if(_currentSongName != nil && (_currentAlbum == nil))
        [albumArtSearchTerm appendString: _currentSongName];
    
    albumArtSearchTerm = [NSMutableString stringWithString:[albumArtSearchTerm removeIrrelevantWhitespace]];
    [albumArtSearchTerm appendString:@" album art"];
    return albumArtSearchTerm;
}

- (void)removeAlbumArtFromSongAndDisk  //ONLY call when commiting saved changes to disk!
{
    [_songIAmEditing removeAlbumArt];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    [self dismissModalViewControllerAnimated:YES];
    
    self.currentAlbumArt = image;
    [self.tableView reloadData];
}

#pragma mark - Rotation status bar methods
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // only iOS 7 methods, check http://stackoverflow.com/questions/18525778/status-bar-still-showing
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (BOOL)prefersStatusBarHidden
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        return YES;
    }
    else
        return NO;  //returned when in portrait, or when app is first launching (UIInterfaceOrientationUnknown)
}

#pragma mark - AlertView
- (void)launchAlertViewWithDialog
{
    NSString * msg = @"This item is specific to this songs current album. To change this item, please edit the album directly, or remove this song from the album.";
    SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:@"Cannot Edit Album Art"
                                                      message:msg
                                                     delegate:self
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:@"Go to Album", nil];
    
    alert.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    alert.messageLabelFont = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize]];
    alert.suggestedButtonFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    [alert show];
}

- (void)alertView:(SDCAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)  //ok tapped
        return;
    if(buttonIndex == 1){  //segue to album edit (user wants to change album art i guess?)

    }
}

@end
