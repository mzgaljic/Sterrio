//
//  MZSongModifierTableView.m
//  Muzic
//
//  Created by Mark Zgaljic on 1/20/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZSongModifierTableView.h"

@interface MZSongModifierTableView ()
{
    BOOL canShowAddtoLibButton;
    UIActivityIndicatorView *spinner;
}
@property (nonatomic, strong) UIImage *currentAlbumArt;
@property (nonatomic, strong) UIImage *currentSmallAlbumArt;
@property (nonatomic, assign) BOOL creatingANewSong;
@end

@implementation MZSongModifierTableView
@synthesize songIAmEditing = _songIAmEditing;
static BOOL PRODUCTION_MODE;
static int const HEIGHT_OF_ALBUM_ART_CELL = 120;

#pragma mark - Other stuff
- (void)initWasCalled
{
    if(_songIAmEditing == nil){
        self.creatingANewSong = YES;
        _songIAmEditing = [Song createNewSongWithNoNameAndManagedContext:[CoreDataManager context]];
    }
    
    self.delegate = self;
    self.dataSource = self;
    
    
    [self setProductionModeValue];
    [AppEnvironmentConstants setUserIsEditingSongOrAlbumOrArtist: YES];
    
    [CoreDataManager context].undoManager = [[NSUndoManager alloc] init];
    [[CoreDataManager context].undoManager beginUndoGrouping];
    
    if(! self.creatingANewSong){
        self.currentAlbumArt = [AlbumArtUtilities albumArtFileNameToUiImage:_songIAmEditing.albumArtFileName];
        if(self.currentAlbumArt == nil)  //maybe this songs album (if it has one) has album art
            if(_songIAmEditing.album != nil)
                self.currentAlbumArt = [AlbumArtUtilities albumArtFileNameToUiImage:_songIAmEditing.album.albumArtFileName];
    }
    
    //remove header gap at top of table, and remove some scrolling space under the delete button (update scroll insets too)
    if(self.creatingANewSong){
        [self setContentInset:UIEdgeInsetsMake(-40,0,-38,0)];
        [self setScrollIndicatorInsets:UIEdgeInsetsMake(-40,0,-38,0)];
    } else{
        [self setContentInset:UIEdgeInsetsMake(-32,0,-30,0)];
        [self setScrollIndicatorInsets:UIEdgeInsetsMake(-32,0,-30,0)];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(existingAlbumHasBeenChosen:)
                                                 name:@"existing album chosen" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(existingArtistHasBeenChosen:)
                                                 name:@"existing artist chosen" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newGenreHasBeenChosen:)
                                                 name:@"new genre has been chosen"
                                               object:nil];

}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"existing album chosen" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"existing artist chosen" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"new genre has been chosen" object:nil];
    [AppEnvironmentConstants setUserIsEditingSongOrAlbumOrArtist: NO];
}

- (void)preDealloc
{
    self.VC = nil;
    self.songIAmEditing = nil;
    self.theDelegate = nil;
}

- (void)setCurrentAlbumArt:(UIImage *)newArt
{
    if(newArt == nil){
        _currentAlbumArt = nil;
        newArt = nil;
        _currentSmallAlbumArt = nil;
        return;
    } else{
        _currentAlbumArt = newArt;
        CGSize size = CGSizeMake(HEIGHT_OF_ALBUM_ART_CELL - 4, HEIGHT_OF_ALBUM_ART_CELL - 4);
        
        //calculate how much one length varies from the other.
        int diff = abs(newArt.size.width - newArt.size.height);
        if(diff > 10){
            //image is not a perfect (or close to perfect) square. Compensate for this...
            _currentSmallAlbumArt = [newArt imageScaledToFitSize:size];
        } else{
            _currentSmallAlbumArt = [AlbumArtUtilities imageWithImage:_currentAlbumArt
                                                         scaledToSize:size];
        }
        
        newArt = nil;
        return;
    }
}

- (void)provideDefaultAlbumArt:(UIImage *)image
{
    [self setCurrentAlbumArt:image];
}

- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

- (void)viewWillAppear:(BOOL)animated
{
    //change background color of tableview
    self.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.VC.parentViewController.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
}

- (void)viewDidAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)canShowAddToLibraryButton
{
    canShowAddtoLibButton = YES;
    if([self numberOfSections] == 2){
        [self reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]]
                    withRowAnimation:UITableViewRowAnimationMiddle];
    }
}


#pragma mark - Tableview delegate implementations
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(_creatingANewSong && _songIAmEditing.songName.length > 0)
        return 2;
    else if(! _creatingANewSong)
        return 2;
    else
        return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)  //rows for editing
        //return 5;  removed genre row
        return 4;
    if(section == 1){  //row to delete this song
        if(_creatingANewSong && _songIAmEditing.songName.length > 0)
            return 1;
        else if(_creatingANewSong)
            return 0;
        else
            return 1;
    }
    else
        return -1;  //crash the app lol
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if(indexPath.section == 0){
        static NSString *cellIdentifier = @"detail label cell";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if(cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                          reuseIdentifier:cellIdentifier];
        if(indexPath.row == 0){  //song name
            cell.textLabel.text = @"Song Name";
            if(_songIAmEditing.songName){
                NSString *detailLabelValue = nil;
                detailLabelValue = _songIAmEditing.songName;
                cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:_songIAmEditing.songName];
            }
            else{
                cell.detailTextLabel.text = nil;
            }
            cell.accessoryView = [MSCellAccessory accessoryWithType:FLAT_DISCLOSURE_INDICATOR color:[[UIColor defaultAppColorScheme] lighterColor]];
            
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
            if(_currentSmallAlbumArt){
                cell.accessoryView.contentMode = UIViewContentModeScaleAspectFit;
                cell.accessoryView = [[UIImageView alloc] initWithImage:_currentSmallAlbumArt];
            }
            else
                cell.accessoryView = nil;
            cell.detailTextLabel.text = @"";
            
        } else if(indexPath.row == 4){/*  //Genre
            cell.textLabel.text = @"Genre";
            if([_songIAmEditing.genreCode intValue] != [GenreConstants noGenreSelectedGenreCode]){
                NSString *genreString = [GenreConstants genreCodeToString:[_songIAmEditing.genreCode intValue]];
                cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:genreString];
            }else{
                cell.detailTextLabel.text = nil;
                cell.accessoryView = [MSCellAccessory accessoryWithType:FLAT_DISCLOSURE_INDICATOR color:[[UIColor defaultAppColorScheme] lighterColor]];
            }*/
        } else
            return nil;
    }
    else if(indexPath.section == 1){
        static NSString *cellIdentifier = @"bottomActionCell";  //delete button or "add to lib" button
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if(cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:cellIdentifier];
        if(indexPath.row == 0){
            if(! _creatingANewSong){
                cell.textLabel.text = @"Delete Song";
                cell.textLabel.textColor = [UIColor redColor];
                
            } else if(_creatingANewSong && _songIAmEditing.songName.length > 0
                      && canShowAddtoLibButton){
                cell.textLabel.text = @"Add to library";
                cell.textLabel.textColor = [UIColor defaultAppColorScheme];
                [spinner stopAnimating];
                spinner = nil;
                
            } else if(_creatingANewSong && _songIAmEditing.songName.length > 0){
                //song name provided, but not all video info needed has loaded
                cell.textLabel.text = @"   Loading additional video info...";
                cell.textLabel.textColor = [UIColor defaultAppColorScheme];
                spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                cell.accessoryView = spinner;
                [spinner startAnimating];
            }
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
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

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section == 0)
        return 10;
    else{
        if([SongPlayerCoordinator isPlayerOnScreen]){
            return [SongPlayerCoordinator heightOfMinimizedPlayer] - 10;  //header is always too big lol
        } else
            return 10;
    }
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
                BOOL fullscreen;
                if(_creatingANewSong)
                    fullscreen = NO;
                else
                    fullscreen = NO;
                EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:_songIAmEditing.songName
                    notificationNameToPost:@"DoneEditingSongField" fullScreen:fullscreen];
                [self.VC.navigationController pushViewController:vc animated:YES];
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
                [popup showInView:self.VC.view];
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
                    [popup showInView:self.VC.view];
                    
                } else{
                    //album picker
                    
                    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Album" delegate:self cancelButtonTitle:@"Cancel"
                                                         destructiveButtonTitle:nil
                                                              otherButtonTitles:@"Choose Album", @"New Album", nil];
                    popup.tag = 2;
                    [popup showInView:self.VC.view];
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
                        [popup showInView:[self.VC view]];
                    }
                    else
                    {   //album art not picked yet, dont show option to remove album art
                        UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Album Art" delegate:self cancelButtonTitle:@"Cancel"
                                                             destructiveButtonTitle:nil
                                                                  otherButtonTitles:@"Choose Photo", @"Search for Art", nil];
                        popup.tag = 3;
                        [popup showInView:[self.VC view]];
                    }
                }
                else
                    //custom alertview, request that user edits album art in the album itself.
                    [self launchAlertViewWithDialog];
                
                _lastTappedRow = 3;
                break;
            }
            case 4://Genres
                /*
                if([_songIAmEditing.genreCode intValue] == [GenreConstants noGenreSelectedGenreCode]){  //adding genre
                    GenrePickerTableViewController *vc;
                    int genreCode = [_songIAmEditing.genreCode intValue];
                    NSString *post = @"new genre has been chosen";
                    BOOL fullscreen;
                    if(_creatingANewSong)
                        fullscreen = YES;
                    else
                        fullscreen = NO;
                    vc = [[GenrePickerTableViewController alloc] initWithGenreCode: genreCode
                                                            notificationNameToPost:post
                                                                        fullScreen:fullscreen];
                    [self.VC.navigationController pushViewController:vc animated:YES];
                } else{  //option to remove genre or choose a different one
                    
                    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Genre" delegate:self cancelButtonTitle:@"Cancel"
                                                         destructiveButtonTitle:@"Remove Genre"
                                                              otherButtonTitles:@"Choose Different Genre", nil];
                    popup.tag = 4;
                    [popup showInView:[self.VC view]];
                }
                
                _lastTappedRow = 4;*/
                break;
        }
    }
    
    if(indexPath.section == 1){
        if(indexPath.row == 0){
            if(! _creatingANewSong){
                [_songIAmEditing removeAlbumArt];
                
                [[CoreDataManager context] deleteObject:_songIAmEditing];
                [[CoreDataManager sharedInstance] saveContext];
                [self.VC dismissViewControllerAnimated:YES completion:nil];
            } else{
                
                [_songIAmEditing setAlbumArt:self.currentAlbumArt];
                
                //save song into library
                BOOL saved = YES;
                NSError *error;
                if ([[CoreDataManager context] save:&error] == NO) {
                    //save failed
                    saved = NO;
                    [MyAlerts displayAlertWithAlertType:ALERT_TYPE_SongSaveHasFailed];
                }
                if(saved)
                {
                    [MyAlerts displayAlertWithAlertType:ALERT_TYPE_SongSaveSuccess];
                    if([SongPlayerCoordinator isPlayerOnScreen])
                    {
                        //may need to update current playback queue
                        SongPlaybackContext aContext;
                        for(int i = 0; i < SongPlaybackContextCount; i++)
                        {
                            aContext = i;
                            if([NowPlaying sharedInstance].context == aContext)
                            {
                                //song may not be in the EXACT queue, but it would be very smart to
                                //re-make the queue just to be sure...
                                CMTime timeAtDisable;
                                AVPlayerItem *disabledPlayerItem;
                                MyAVPlayer *player = (MyAVPlayer *)[MusicPlaybackController obtainRawAVPlayer];
                                BOOL allowSongDidFinishToRunOriginalVal = [player allowSongDidFinishValue];
                                //make copy of AVPlayerItem which will retain buffered data
                                disabledPlayerItem = [player.currentItem copy];
                                timeAtDisable = player.currentItem.currentTime;
                                [player allowSongDidFinishNotificationToProceed:NO];
                                [player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:nil]];
                                
                                //now build the new queue
                                Song *nowPlaying = [NowPlaying sharedInstance].nowPlaying;
                                Playlist *playlist = [NowPlaying sharedInstance].nowPlayingPlaylist;
                                [MusicPlaybackController newQueueWithSong:nowPlaying
                                                              withContext:aContext
                                                         optionalPlaylist:playlist
                                                          skipCurrentSong:YES];
                                //cancel any network operations this caused
                                [[[OperationQueuesSingeton sharedInstance] loadingSongsOpQueue] cancelAllOperations];
                                //now restore player item to exact time without affecting queue state
                                [player replaceCurrentItemWithPlayerItem:disabledPlayerItem];
                                [player seekToTime:timeAtDisable
                                   toleranceBefore:kCMTimeZero
                                    toleranceAfter:kCMTimeZero];
                                [player dismissAllSpinners];
                                [player allowSongDidFinishNotificationToProceed:allowSongDidFinishToRunOriginalVal];
                                break;
                            }
                        }
                    }
                }
                
                [self.theDelegate performCleanupBeforeSongIsSaved:_songIAmEditing];
            }  //end 'creatingNewSong'
        }  //end indexPath.row == 0
        else
            return;
    }
}


#pragma mark - Song editing logic
#pragma mark - Editing text fields and creating new stuff
- (void)songNameEditingComplete:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DoneEditingSongField" object:nil];
    NSString *newName = (NSString *)notification.object;
    newName = [newName removeIrrelevantWhitespace];
    
    if([_songIAmEditing.songName isEqualToString:newName])
        return;
    if(newName.length == 0){  //was all whitespace, or user gave us an empty string
        if(_creatingANewSong){
            _songIAmEditing.songName = nil;
            _songIAmEditing.smartSortSongName = nil;
        }
        [self performSelector:@selector(reloadSongNameCell) withObject:nil afterDelay:0.5];
        return;
    }
    
    _songIAmEditing.songName = newName;
    _songIAmEditing.smartSortSongName = [newName regularStringToSmartSortString];
    //edge case, if name is something like 'the', dont remove all characters! Keep original name.
    if(_songIAmEditing.smartSortSongName.length == 0)
        _songIAmEditing.smartSortSongName = newName;
    [self beginUpdates];
    [self reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                withRowAnimation:UITableViewRowAnimationFade];
    if(_creatingANewSong){
        if(! [self isRowPresentInTableView:0 withSection:1]){
            [self insertSections:[NSIndexSet indexSetWithIndex:1]
                withRowAnimation:UITableViewRowAnimationNone];
        }
    }
    [self endUpdates];
    [self reloadData];
    
    __weak MZSongModifierTableView *weakself = self;
    // Delay execution of my block for 10 seconds.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(weakself)
            [weakself scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]
                    atScrollPosition:UITableViewScrollPositionTop animated:YES];
    });
}

- (BOOL)isRowPresentInTableView:(int)row withSection:(int)section
{
    if(section < [self numberOfSections])
    {
        if(row < [self numberOfRowsInSection:section])
        {
            return YES;
        }
    }
    return NO;
}

- (void)reloadTableWaitUntilDone
{
    [self reloadData];
}

//added this since it caused a crash on iphone 4s
- (void)reloadSongNameCell
{
    [self beginUpdates];
    [self reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                withRowAnimation:UITableViewRowAnimationAutomatic];
    [self endUpdates];
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
    if(_songIAmEditing.album){  //song had album
        if(! _songIAmEditing.album.artist){  //album does NOT have an artist
            newArtist = [Artist createNewArtistWithName:artistName usingAlbum:_songIAmEditing.album inManagedContext:[CoreDataManager context]];
        } else{  //album already has artist, remove this song from the album.
            _songIAmEditing.album = nil;
        }
    }
    else
        newArtist = [Artist createNewArtistWithName:artistName inManagedContext:[CoreDataManager context]];
    if(_songIAmEditing.artist)
        [[CoreDataManager context] deleteObject:_songIAmEditing.artist];
    _songIAmEditing.artist = newArtist;
    
    [self beginUpdates];
    [self reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]
                withRowAnimation:UITableViewRowAnimationFade];
    [self endUpdates];
    [self reloadData];
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
        [AlbumArtUtilities makeCopyOfArtWithName:_songIAmEditing.album.albumArtFileName andNameIt:@"temp art-editing mode-Mark Zgaljic.jpg"];
        [AlbumArtUtilities deleteAlbumArtFileWithName:_songIAmEditing.album.albumArtFileName];
        [[CoreDataManager context] deleteObject:_songIAmEditing.album];
    }
    _songIAmEditing.album = newAlbum;
    if(_songIAmEditing.artist)
        newAlbum.artist = _songIAmEditing.artist;

    [self beginUpdates];
    [self reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]]
                withRowAnimation:UITableViewRowAnimationFade];
    [self endUpdates];
    [self reloadData];
}

#pragma mark - existing album and artist chosen
- (void)existingAlbumHasBeenChosen:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"existing album chosen"]){
        if(_songIAmEditing.album)
        {
            [AlbumArtUtilities makeCopyOfArtWithName:_songIAmEditing.album.albumArtFileName andNameIt:@"temp art-editing mode-Mark Zgaljic.jpg"];
            [AlbumArtUtilities deleteAlbumArtFileWithName:_songIAmEditing.album.albumArtFileName];
            [[CoreDataManager context] deleteObject:_songIAmEditing.album];
        }
        
        _songIAmEditing.album = (Album *)notification.object;
        self.currentAlbumArt = [AlbumArtUtilities albumArtFileNameToUiImage:_songIAmEditing.album.albumArtFileName];
        _songIAmEditing.artist = _songIAmEditing.album.artist;
        _songIAmEditing.genreCode = _songIAmEditing.album.genreCode;
        
        [self beginUpdates];
        [self reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]]
                    withRowAnimation:UITableViewRowAnimationFade];
        [self endUpdates];
        [self reloadData];
    }
}

- (void)existingArtistHasBeenChosen:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"existing artist chosen"]){
        if(_songIAmEditing.artist)
            [[CoreDataManager context] deleteObject:_songIAmEditing.artist];
        _songIAmEditing.artist = (Artist *)notification.object;
        
        [self beginUpdates];
        [self reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]
                    withRowAnimation:UITableViewRowAnimationFade];
        [self endUpdates];
        [self reloadData];
    }
}

- (void)newGenreHasBeenChosen:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"new genre has been chosen"]){
        NSString *genreString = (NSString *)notification.object;
        _songIAmEditing.genreCode = [NSNumber numberWithInt:[GenreConstants genreStringToCode:genreString]];
        
        [self beginUpdates];
        [self reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:4 inSection:0]]
                    withRowAnimation:UITableViewRowAnimationFade];
        [self endUpdates];
        [self reloadData];
    }
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
                    //[self.VC.navigationController pushViewController:vc animated:YES];
                    [self performSelector:@selector(showUnsupportedAlert) withObject:nil afterDelay:0.7];
                } else if(_songIAmEditing.artist){  //remove from current artist
                    _songIAmEditing.artist = nil;
                    [self reloadData];
                }
            }
                break;
            case 1:
                if(! _songIAmEditing.artist){
                    //create a new artist
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(artistNameCreationCompleteAndSetUpArtist:)
                                                                 name:@"DoneEditingArtistField" object:nil];
                    BOOL fullscreen;
                    if(_creatingANewSong)
                        fullscreen = NO;
                    else
                        fullscreen = NO;
                    EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:nil
                        notificationNameToPost:@"DoneEditingArtistField" fullScreen:fullscreen];
                    [self.VC.navigationController pushViewController:vc animated:YES];
                    
                } else if(_songIAmEditing.artist){//choose different artist
                    ExistingArtistPickerTableViewController *vc = [[ExistingArtistPickerTableViewController alloc]
                                                                   initWithCurrentArtist:_songIAmEditing.artist];
                    [self.VC.navigationController pushViewController:vc animated:YES];
                }
                break;
            case 2:
            {
                if(_songIAmEditing.artist){
                    //create new artist
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(artistNameCreationCompleteAndSetUpArtist:)
                                                                 name:@"DoneEditingArtistField" object:nil];
                    BOOL fullscreen;
                    if(_creatingANewSong)
                        fullscreen = NO;
                    else
                        fullscreen = NO;
                    
                    EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:nil
                                    notificationNameToPost:@"DoneEditingArtistField"
                                               fullScreen:fullscreen];
                    [self.VC.navigationController pushViewController:vc animated:YES];
                    
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
                    [self reloadData];
                } else{ //choose existing album
                    /*
                    ExistingAlbumPickerTableViewController *vc = [[ExistingAlbumPickerTableViewController alloc]
                                                                  initWithCurrentAlbum:_songIAmEditing.album];
                    //[self.VC.navigationController pushViewController:vc animated:YES];*/
                    [self performSelector:@selector(showUnsupportedAlert) withObject:nil afterDelay:0.7];
                }
                break;
            case 1:
                if(! _songIAmEditing.album){  //create new album
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumNameCreationCompleteAndSetUpAlbum:)
                                                                 name:@"DoneEditingAlbumField" object:nil];
                    BOOL fullscreen;
                    if(_creatingANewSong)
                        fullscreen = NO;
                    else
                        fullscreen = NO;
                    EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:nil
                                                                                                  notificationNameToPost:@"DoneEditingAlbumField" fullScreen:fullscreen];
                    [self.VC.navigationController pushViewController:vc animated:YES];
                    break;
                } else{  //place in different album (existing album picker)
                    [self performSelector:@selector(showUnsupportedAlert) withObject:nil afterDelay:0.7];
                    /*
                    ExistingAlbumPickerTableViewController *vc = [[ExistingAlbumPickerTableViewController alloc]
                                                                  initWithCurrentAlbum:_songIAmEditing.album];
                    [self.VC.navigationController pushViewController:vc animated:YES];
                     */
                }
                
                break;
            case 2:
                if(_songIAmEditing.album){  //create new album
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumNameCreationCompleteAndSetUpAlbum:)
                                                                 name:@"DoneEditingAlbumField" object:nil];
                    BOOL fullscreen;
                    if(_creatingANewSong)
                        fullscreen = NO;
                    else
                        fullscreen = NO;

                    EditableCellTableViewController *vc;
                    vc = [[EditableCellTableViewController alloc]
                                   initWithEditingString:nil
                                   notificationNameToPost:@"DoneEditingAlbumField"
                                     fullScreen:fullscreen];
                    [self.VC.navigationController pushViewController:vc animated:YES];
                } else{
                    //remove song from album
                    _songIAmEditing.album = nil;
                    [self reloadData];
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
                [self reloadData];
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
                [self reloadData];
                break;
            case 1:  //find a different genre
            {
                GenrePickerTableViewController *vc;
                int genreCode = [_songIAmEditing.genreCode intValue];
                NSString *post = @"new genre has been chosen";
                BOOL fullscreen;
                if(_creatingANewSong)
                    fullscreen = NO;
                else
                    fullscreen = NO;
                vc = [[GenrePickerTableViewController alloc] initWithGenreCode: genreCode
                                                        notificationNameToPost:post
                                                                    fullScreen:fullscreen];
                [self.VC.navigationController pushViewController:vc animated:YES];
                break;
            }
            case 2:  //cancel
                break;
            default:
                break;
        }
    }
}

#pragma mark - Unsupported actions code
- (void)showUnsupportedAlert
{
    SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:@"Unfinished"
                                                      message:@"This action is not yet supported."
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles: nil];
    alert.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    alert.messageLabelFont = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    alert.suggestedButtonFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    [alert show];
}

#pragma mark - Album Art Methods
- (void)pickNewAlbumArtFromPhotos
{
    UIImagePickerController *photoPickerController = [[UIImagePickerController alloc] init];
    photoPickerController.delegate = self;
    //set tint color specifically for this VC so that the cancel buttons are invisible
    [photoPickerController.view setTintColor:[UIColor defaultWindowTintColor]];
    [self.theDelegate pushThisVC:photoPickerController];
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *img = [info objectForKey:UIImagePickerControllerOriginalImage];
    if(img == nil)
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotOpenSelectedImageError];
    self.currentAlbumArt = img;
    NSArray *paths = @[[NSIndexPath indexPathForRow:3 inSection:0]];
    [self reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
}


#pragma mark - public methods
- (void)cancelEditing
{
    [[CoreDataManager context].undoManager endUndoGrouping];
    [[CoreDataManager context].undoManager undo];
    [CoreDataManager context].undoManager = nil;
    
    //restore old album art file
    if(_songIAmEditing.album)
        [AlbumArtUtilities makeCopyOfArtWithName:@"temp art-editing mode-Mark Zgaljic.jpg" andNameIt:_songIAmEditing.album.albumArtFileName];
    else
        [AlbumArtUtilities makeCopyOfArtWithName:@"temp art-editing mode-Mark Zgaljic.jpg" andNameIt:_songIAmEditing.albumArtFileName];
    [AlbumArtUtilities deleteAlbumArtFileWithName:@"temp art-editing mode-Mark Zgaljic.jpg"];
    
    if(self.creatingANewSong){
        //dont need to warn that im about to delete the song, its impossible for the user to be
        //listening to this song if he never finished creating it.
        [[CoreDataManager context] deleteObject:_songIAmEditing];
    }
    
    NSError *error = nil;
    [[CoreDataManager context] save:&error];  //saves the context to disk

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SongEditDone" object:nil];
    [self.VC dismissViewControllerAnimated:YES completion:nil];
}

//this method is only used for ACTUAL editing. Song creation is handled in "didSelectCell..."
- (void)songEditingWasSuccessful
{
    [[CoreDataManager context].undoManager endUndoGrouping];
    [CoreDataManager context].undoManager = nil;
    
    //need to create copy of image in memory since we are deleting the original
    UIImage *currImg = self.currentAlbumArt;
    CGRect placeholderImgRect = CGRectMake(0, 0, currImg.size.width, currImg.size.height);
    CGImageRef imageRef = CGImageCreateWithImageInRect(currImg.CGImage, placeholderImgRect);
    UIImage *tempPlaceHolder = [UIImage imageWithCGImage:imageRef];
    
    //delete current album art on disk in case there was one set. Skipping this would cause
    //the new art to not be saved (setAlbumArt method tries to optimize the saving...)
    NSString *artFileName = [NSString stringWithFormat:@"%@.jpg", _songIAmEditing.song_id];
    [AlbumArtUtilities deleteAlbumArtFileWithName:artFileName];
    
    //save the new album art
    if(_songIAmEditing.album)
        [_songIAmEditing.album setAlbumArt:tempPlaceHolder];
    else
        [_songIAmEditing setAlbumArt:tempPlaceHolder];
    
    //delete temp copy of old art file
    if([AlbumArtUtilities isAlbumArtAlreadySavedOnDisk:@"temp art-editing mode-Mark Zgaljic"]){
        [AlbumArtUtilities deleteAlbumArtFileWithName:@"temp art-editing mode-Mark Zgaljic.jpg"];
    }
    
    [[CoreDataManager sharedInstance] saveContext]; //saves the context to disk
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SongEditDone" object:nil];
    
    [self.VC dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AlertView
- (void)launchAlertViewWithDialog
{
    NSString * msg = @"This song is part of an album in your library. Therefore, any changes to the album art must be made on the album itself.";
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
        [self performSelector:@selector(showUnsupportedAlert) withObject:nil afterDelay:0.7];
    }
}

@end
