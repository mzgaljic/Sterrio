//
//  MasterEditingSongTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/17/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterEditingSongTableViewController.h"

@interface MasterEditingSongTableViewController ()
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
    
    //change background color of tableview
    self.tableView.backgroundColor = [UIColor clearColor];
    self.parentViewController.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setProductionModeValue];
    [AppEnvironmentConstants setUserIsEditingSongOrAlbumOrArtist: YES];
    
    [CoreDataManager context].undoManager = [[NSUndoManager alloc] init];
    [[CoreDataManager context].undoManager beginUndoGrouping];
    self.currentAlbumArt = [AlbumArtUtilities albumArtFileNameToUiImage:_songIAmEditing.albumArtFileName];
    if(self.currentAlbumArt == nil)  //maybe this songs album (if it has one) has album art
        if(_songIAmEditing.album != nil)
            self.currentAlbumArt = [AlbumArtUtilities albumArtFileNameToUiImage:_songIAmEditing.album.albumArtFileName];
    
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

- (void)viewDidAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"existing album chosen" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"existing artist chosen" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"new genre has been chosen" object:nil];
    [AppEnvironmentConstants setUserIsEditingSongOrAlbumOrArtist: NO];
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
            cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:_songIAmEditing.songName];
            
        } else if(indexPath.row == 1){  //artist
            cell.textLabel.text = @"Artist";
            if(_songIAmEditing.artist != nil)
                cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:_songIAmEditing.artist.artistName];
            else
                cell.detailTextLabel.text = @"";
                
        } else if(indexPath.row == 2){  //Album
            cell.textLabel.text = @"Album";
            if(_songIAmEditing.album != nil)
                cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:_songIAmEditing.album.albumName];
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
            if([_songIAmEditing.genreCode intValue] != [GenreConstants noGenreSelectedGenreCode]){
                NSString *genreString = [GenreConstants genreCodeToString:[_songIAmEditing.genreCode intValue]];
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
            cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
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
                EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:_songIAmEditing.songName
                                                                                              notificationNameToPost:@"DoneEditingSongField"];
                [self.navigationController pushViewController:vc animated:YES];
                break;
            }
            case 1:  //editing artist
            {
                UIActionSheet *popup;
                if(! _songIAmEditing.artist){
                    popup = [[UIActionSheet alloc] initWithTitle:@"Artist" delegate:self cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:nil otherButtonTitles:@"Choose Artist", @"New Artist", nil];
                } else if(_songIAmEditing.artist){
                    popup = [[UIActionSheet alloc] initWithTitle:@"Artist" delegate:self cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:@"Remove From Artist" otherButtonTitles:@"Choose Different Artist", @"New Artist", nil];
                }
                
                popup.tag = 1;
                [popup showInView:self.navigationController.view];
                _lastTappedRow = 1;
                break;
            }
            case 2:  //editing album
            {
                if(_songIAmEditing.album){
                    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Album" delegate:self cancelButtonTitle:@"Cancel"
                                                         destructiveButtonTitle:@"Remove Song From Album"
                                                              otherButtonTitles:@"Choose Different Album", @"New Album", nil];
                    popup.tag = 2;
                    [popup showInView:self.navigationController.view];
                    
                } else{
                    //album picker
                    
                    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Album" delegate:self cancelButtonTitle:@"Cancel"
                                                         destructiveButtonTitle:nil
                                                              otherButtonTitles:@"Choose Album", @"New Album", nil];
                    popup.tag = 2;
                    [popup showInView:self.navigationController.view];
                }
                _lastTappedRow = 2;
                break;
            }
            case 3:  //editing album art
            {//can only edit album art w/ a song that is part of an album IF you edit the album itself.
                if(! _songIAmEditing.album.albumArtFileName)
                {
                    if(_currentAlbumArt)  //song already contains album art
                    {  //ask to remove art or add new art (photo or safari)
                        UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Album Art" delegate:self cancelButtonTitle:@"Cancel"
                                                             destructiveButtonTitle:@"Remove Art"
                                                                  otherButtonTitles:@"Choose Different Photo", @"Search for Art", nil];
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
                if([_songIAmEditing.genreCode intValue] == [GenreConstants noGenreSelectedGenreCode]){  //adding genre
                    GenrePickerTableViewController *vc = [[GenrePickerTableViewController alloc] initWithGenreCode:[_songIAmEditing.genreCode intValue]
                                                                                            notificationNameToPost:@"new genre has been chosen"];
                    [self.navigationController pushViewController:vc animated:YES];
                } else{  //option to remove genre or choose a different one
                    
                    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Genre" delegate:self cancelButtonTitle:@"Cancel"
                                                         destructiveButtonTitle:@"Remove Genre"
                                                              otherButtonTitles:@"Choose Different Genre", nil];
                    popup.tag = 4;
                    [popup showInView:[self.navigationController view]];
                }
                
                _lastTappedRow = 4;
                break;
        }
    }
    
    if(indexPath.section == 1){
        if(indexPath.row == 0){
            //check if song is in queue
            [MusicPlaybackController songAboutToBeDeleted:_songIAmEditing];
            [_songIAmEditing removeAlbumArt];
            
            [[CoreDataManager context] deleteObject:_songIAmEditing];
            [[CoreDataManager sharedInstance] saveContext];
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
    
    if([_songIAmEditing.songName isEqualToString:newName])
        return;
    if(newName.length == 0)  //was all whitespace, or user gave us an empty string
        return;
    
    _songIAmEditing.songName = newName;
    _songIAmEditing.smartSortSongName = [newName regularStringToSmartSortString];
    if(_songIAmEditing.smartSortSongName.length == 0)  //edge case...if name itself is just something like 'the', dont remove all characters! Keep original name.
        _songIAmEditing.smartSortSongName = newName;
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
    
    Artist *newArtist;
    if(_songIAmEditing.album)
        newArtist = [Artist createNewArtistWithName:artistName usingAlbum:_songIAmEditing.album inManagedContext:[CoreDataManager context]];
    else
        newArtist = [Artist createNewArtistWithName:artistName inManagedContext:[CoreDataManager context]];
    if(_songIAmEditing.artist)
        [[CoreDataManager context] deleteObject:_songIAmEditing.artist];
    _songIAmEditing.artist = newArtist;
    
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
    
    Album *newAlbum = [Album createNewAlbumWithName:albumName usingSong:_songIAmEditing inManagedContext:[CoreDataManager context]];
    if(_songIAmEditing.album)
    {
        [AlbumArtUtilities makeCopyOfArtWithName:_songIAmEditing.album.albumArtFileName andNameIt:@"temp art-editing mode-Mark Zgaljic.png"];
        [AlbumArtUtilities deleteAlbumArtFileWithName:_songIAmEditing.album.albumArtFileName];
        [[CoreDataManager context] deleteObject:_songIAmEditing.album];
    }
    _songIAmEditing.album = newAlbum;
    if(_songIAmEditing.artist)
        newAlbum.artist = _songIAmEditing.artist;
    
    [self.tableView reloadData];
}

#pragma mark - existing album and artist chosen
- (void)existingAlbumHasBeenChosen:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"existing album chosen"]){
        if(_songIAmEditing.album)
        {
            [AlbumArtUtilities makeCopyOfArtWithName:_songIAmEditing.album.albumArtFileName andNameIt:@"temp art-editing mode-Mark Zgaljic.png"];
            [AlbumArtUtilities deleteAlbumArtFileWithName:_songIAmEditing.album.albumArtFileName];
            [[CoreDataManager context] deleteObject:_songIAmEditing.album];
        }
        
        _songIAmEditing.album = (Album *)notification.object;
        self.currentAlbumArt = [AlbumArtUtilities albumArtFileNameToUiImage:_songIAmEditing.album.albumArtFileName];
        _songIAmEditing.artist = _songIAmEditing.album.artist;
        _songIAmEditing.genreCode = _songIAmEditing.album.genreCode;
        
        [self.tableView reloadData];
    }
}

- (void)existingArtistHasBeenChosen:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"existing artist chosen"]){
        if(_songIAmEditing.artist)
            [[CoreDataManager context] deleteObject:_songIAmEditing.artist];
        _songIAmEditing.artist = (Artist *)notification.object;
        
        [self.tableView reloadData];
    }
}

- (void)newGenreHasBeenChosen:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"new genre has been chosen"]){
        _songIAmEditing.genreCode = [NSNumber numberWithInt:[GenreConstants genreStringToCode:(NSString *)notification.object]];
        [self.tableView reloadData];
    }
}

#pragma mark - nav bar buttons
- (IBAction)leftBarButtonTapped:(id)sender  //cancel
{
    [[CoreDataManager context].undoManager endUndoGrouping];
    [[CoreDataManager context].undoManager undo];
    [CoreDataManager context].undoManager = nil;
    
    //restore old album art file
    if(_songIAmEditing.album)
        [AlbumArtUtilities makeCopyOfArtWithName:@"temp art-editing mode-Mark Zgaljic.png" andNameIt:_songIAmEditing.album.albumArtFileName];
    else
        [AlbumArtUtilities makeCopyOfArtWithName:@"temp art-editing mode-Mark Zgaljic.png" andNameIt:_songIAmEditing.albumArtFileName];
    [AlbumArtUtilities deleteAlbumArtFileWithName:@"temp art-editing mode-Mark Zgaljic.png"];
    
    //tell MasterSongsTableViewController that it should leave editing mode since song editing has completed.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SongEditDone" object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)rightBarButtonTapped:(id)sender  //save
{
    [[CoreDataManager context].undoManager endUndoGrouping];
    [CoreDataManager context].undoManager = nil;
    
    //make sure album art file name is what it should be (on disk)...this updates it
    if(_songIAmEditing.album)
        [_songIAmEditing.album setAlbumArt:_currentAlbumArt];
    else
        [_songIAmEditing setAlbumArt:_currentAlbumArt];
    
    //delete temp copy of old art file
    [AlbumArtUtilities deleteAlbumArtFileWithName:@"temp art-editing mode-Mark Zgaljic.png"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SongSavedDuringEdit" object:_songIAmEditing];
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
                if(! _songIAmEditing.artist){  //add song to an existing artist
                    ExistingArtistPickerTableViewController *vc = [[ExistingArtistPickerTableViewController alloc]
                                                                   initWithCurrentArtist:_songIAmEditing.artist];
                    [self.navigationController pushViewController:vc animated:YES];
                } else if(_songIAmEditing.artist){  //remove from current artist
                    _songIAmEditing.artist = nil;
                    [self.tableView reloadData];
                }
            }
                break;
            case 1:
                if(! _songIAmEditing.artist){
                    //create a new artist
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(artistNameCreationCompleteAndSetUpArtist:)
                                                                 name:@"DoneEditingArtistField" object:nil];
                    EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:nil
                                                                                                  notificationNameToPost:@"DoneEditingArtistField"];
                    [self.navigationController pushViewController:vc animated:YES];
                    
                } else if(_songIAmEditing.artist){//choose different artist
                    ExistingArtistPickerTableViewController *vc = [[ExistingArtistPickerTableViewController alloc]
                                                                   initWithCurrentArtist:_songIAmEditing.artist];
                    [self.navigationController pushViewController:vc animated:YES];
                }
                break;
            case 2:
            {
                if(_songIAmEditing.artist){
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
                if(_songIAmEditing.album){  //remove song from album (and reset some data)
                    _songIAmEditing.album = nil;
                    [self.tableView reloadData];
                } else{ //choose existing album
                    ExistingAlbumPickerTableViewController *vc = [[ExistingAlbumPickerTableViewController alloc]
                                                                  initWithCurrentAlbum:_songIAmEditing.album];
                    [self.navigationController pushViewController:vc animated:YES];
                }
                break;
            case 1:
                if(! _songIAmEditing.album){  //create new album
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumNameCreationCompleteAndSetUpAlbum:)
                                                                 name:@"DoneEditingAlbumField" object:nil];
                    EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:nil
                                                                                                  notificationNameToPost:@"DoneEditingAlbumField"];
                    [self.navigationController pushViewController:vc animated:YES];
                    break;
                } else{  //place in different album (existing album picker)
                    ExistingAlbumPickerTableViewController *vc = [[ExistingAlbumPickerTableViewController alloc]
                                                                  initWithCurrentAlbum:_songIAmEditing.album];
                    [self.navigationController pushViewController:vc animated:YES];
                }
                
                break;
            case 2:
                if(_songIAmEditing.album){  //create new album
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumNameCreationCompleteAndSetUpAlbum:)
                                                                 name:@"DoneEditingAlbumField" object:nil];
                    EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:nil
                                                                                                  notificationNameToPost:@"DoneEditingAlbumField"];
                    [self.navigationController pushViewController:vc animated:YES];
                } else{
                    //remove song from album
                    _songIAmEditing.album = nil;
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
                _songIAmEditing.genreCode = [NSNumber numberWithInt:[GenreConstants noGenreSelectedGenreCode]];
                [self.tableView reloadData];
                break;
            case 1:  //find a different genre
            {
                GenrePickerTableViewController *vc = [[GenrePickerTableViewController alloc] initWithGenreCode:[_songIAmEditing.genreCode intValue]
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
    //set tint color specifically for this VC so that the cancel buttons arent invisible
    [photoPickerController.view setTintColor:[UIColor defaultWindowTintColor]];
    [self presentViewController:photoPickerController animated:YES completion:nil];
}

- (void)jumpToSafariToFindAlbumArt
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"x-web-search://?%@", [[self buildAlbumArtSearchString] stringForHTTPRequest]]];
    
    if (![[UIApplication sharedApplication] openURL:url])
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotOpenSafariError];
}

- (NSString *)buildAlbumArtSearchString
{
    NSMutableString *albumArtSearchTerm = [NSMutableString stringWithString:@""];
    if(_songIAmEditing.album != nil)
        [albumArtSearchTerm appendString: _songIAmEditing.album.albumName];
    [albumArtSearchTerm appendString:@" "];
    
    if(_songIAmEditing.artist != nil)
        [albumArtSearchTerm appendString: _songIAmEditing.artist.artistName];
    [albumArtSearchTerm appendString:@" "];
    
    if(_songIAmEditing.songName != nil && (_songIAmEditing.album == nil))
        [albumArtSearchTerm appendString: _songIAmEditing.songName];
    
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
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
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
