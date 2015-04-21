//
//  MZSongModifierTableView.m
//  Muzic
//
//  Created by Mark Zgaljic on 1/20/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZSongModifierTableView.h"
#import "AlbumAlbumArt+Utilities.h"
#import "SongAlbumArt+Utilities.h"

@interface MZSongModifierTableView ()
{
    BOOL canShowAddtoLibButton;
    BOOL userReplacedDefaultYoutubeArt;
    UIActivityIndicatorView *spinner;
}
@property (nonatomic, strong) UIImage *currentAlbumArt;
@property (nonatomic, strong) UIImage *currentSmallAlbumArt;
@property (nonatomic, assign) BOOL creatingANewSong;
@end

@implementation MZSongModifierTableView
@synthesize songIAmEditing = _songIAmEditing;
static BOOL PRODUCTION_MODE;
float const MAX_ALBUM_ART_CELL_HEIGHT = 160;
float const updateCellWithAnimationFadeDelay = 0.4;


#pragma mark - Other stuff
- (void)initWasCalled
{
    if(_songIAmEditing == nil){
        self.creatingANewSong = YES;
        NSManagedObjectContext *context = [CoreDataManager context];
        _songIAmEditing = [Song createNewSongWithNoNameAndManagedContext:context];
        SongAlbumArt *newArtObj = [SongAlbumArt createNewAlbumArtWithUIImage:nil withContext:context];
        _songIAmEditing.albumArt = newArtObj;
    }
    
    self.delegate = self;
    self.dataSource = self;
    
    [self setProductionModeValue];
    [AppEnvironmentConstants setUserIsEditingSongOrAlbumOrArtist: YES];
    userReplacedDefaultYoutubeArt = NO;
    
    if(! self.creatingANewSong){
        self.currentAlbumArt = [_songIAmEditing.albumArt imageFromImageData];
    }
    
    //remove header gap at top of table, and remove some scrolling space under the delete button (update scroll insets too)
    if(self.creatingANewSong){
        [self setContentInset:UIEdgeInsetsMake(-40,0,-38,0)];
        [self setScrollIndicatorInsets:UIEdgeInsetsMake(-40,0,-38,0)];
    } else{
        [self setContentInset:UIEdgeInsetsMake(-32,0,-30,0)];
        [self setScrollIndicatorInsets:UIEdgeInsetsMake(-32,0,-30,0)];
    }
}

- (Song *)songObjectGivenSongId:(NSString *)songId
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Song"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"song_id == %@", songId];
    //descriptor doesnt really matter here
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"songName"
                                                                     ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    NSArray *results = [[CoreDataManager context] executeFetchRequest:fetchRequest error:nil];
    if(results.count == 1)
        return results[0];
    else
        return nil;
}

- (Album *)albumObjectGivenAlbumId:(NSString *)albumId
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Album"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"album_id == %@", albumId];
    //descriptor doesnt really matter here
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"albumName"
                                                                     ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    NSArray *results = [[CoreDataManager context] executeFetchRequest:fetchRequest error:nil];
    if(results.count == 1)
        return results[0];
    else
        return nil;
}

- (void)dealloc
{
    [AppEnvironmentConstants setUserIsEditingSongOrAlbumOrArtist: NO];
    //doing this just in case. found a bug once where tab bar was gone after this editor closing.
    [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated object:@NO];
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
        CGSize size = [self albumArtSizeGivenPrefSizeSetting];
        
        //calculate how much one length varies from the other.
        int diff = abs((int)newArt.size.width - (int)newArt.size.height);
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

- (CGSize)albumArtSizeGivenPrefSizeSetting
{
    int heightOfAlbumArtCell = [PreferredFontSizeUtility actualCellHeightFromCurrentPreferredSize] *2;
    if(heightOfAlbumArtCell > MAX_ALBUM_ART_CELL_HEIGHT)
        heightOfAlbumArtCell = MAX_ALBUM_ART_CELL_HEIGHT;
    return  CGSizeMake(heightOfAlbumArtCell - 4, heightOfAlbumArtCell - 4);
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
                cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:detailLabelValue];
            }
            else{
                cell.detailTextLabel.text = @"  ";
            }
            cell.accessoryView = [MSCellAccessory accessoryWithType:FLAT_DISCLOSURE_INDICATOR color:[[UIColor defaultAppColorScheme] lighterColor]];
            
        } else if(indexPath.row == 1){  //artist
            cell.textLabel.text = @"Artist";
            if(_songIAmEditing.artist != nil)
                cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:_songIAmEditing.artist.artistName];
            else
                cell.detailTextLabel.text = @"  ";
            cell.accessoryView = nil;
            
        } else if(indexPath.row == 2){  //Album
            cell.textLabel.text = @"Album";
            if(_songIAmEditing.album != nil)
                cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:_songIAmEditing.album.albumName];
            else
                cell.detailTextLabel.text = @"  ";
            cell.accessoryView = nil;
            
        } else if(indexPath.row == 3){  //Album Art
            cell.textLabel.text = @"Album Art";
            if(_currentSmallAlbumArt){
                cell.accessoryView.contentMode = UIViewContentModeScaleAspectFit;
                cell.accessoryView = [[UIImageView alloc] initWithImage:_currentSmallAlbumArt];
            }
            else
                cell.accessoryView = nil;
            cell.detailTextLabel.text = @"  ";
            
        }else
            return nil;
        
        int fontSize;
        if([AppEnvironmentConstants preferredSizeSetting] < 5
           && [AppEnvironmentConstants preferredSizeSetting] > 1)
            fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
        else
            fontSize = [PreferredFontSizeUtility hypotheticalLabelFontSizeForPreferredSize:4];
        
        cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                              size:fontSize];
        cell.detailTextLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                    size:fontSize];
    }
    else if(indexPath.section == 1){
        static NSString *cellIdentifier = @"bottomActionCell";  //delete button or "add to lib" button
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if(cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:cellIdentifier];
        if(indexPath.row == 0){
            if(_creatingANewSong && _songIAmEditing.songName.length > 0
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
            cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                  size:17.0f];
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
        if([SongPlayerCoordinator isPlayerOnScreen] && _creatingANewSong){
            return [SongPlayerCoordinator heightOfMinimizedPlayer] - 10;  //header is always too big lol
        } else
            return 10;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int prefCellHeight;
    int prefSizeSetting = [AppEnvironmentConstants preferredSizeSetting];
    if(prefSizeSetting >= 3 && prefSizeSetting < 6)
        prefCellHeight = [PreferredFontSizeUtility actualCellHeightFromCurrentPreferredSize];
    else if(prefSizeSetting < 3)
        prefCellHeight = [PreferredFontSizeUtility hypotheticalCellHeightForPreferredSize:3];
    else
        prefCellHeight = [PreferredFontSizeUtility hypotheticalCellHeightForPreferredSize:5];
    
    if(indexPath.row == 3)  //album art cell
        return prefCellHeight * 2;
    else
        return prefCellHeight * .7;
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
                _lastTappedRow = 3;
                break;
            }
        }
    }
    
    if(indexPath.section == 1){
        if(indexPath.row == 0){
            if(_creatingANewSong){
                
                if(self.currentAlbumArt){
                    _songIAmEditing.albumArt.image = [AlbumArtUtilities compressedDataFromUIImage:self.currentAlbumArt];
                }
                
                //save song into library
                BOOL saved = YES;
                NSError *error;
                [self.theDelegate performCleanupBeforeSongIsSaved:_songIAmEditing];
                
                if ([[CoreDataManager context] save:&error] == NO) {
                    //save failed
                    saved = NO;
                    [MyAlerts displayAlertWithAlertType:ALERT_TYPE_SongSaveHasFailed];
                }
                else
                {
                    //save success
                    if(! userReplacedDefaultYoutubeArt){
                        [LQAlbumArtBackgroundUpdater downloadHqAlbumArtWhenConvenientForSongId:_songIAmEditing.song_id];
                        [LQAlbumArtBackgroundUpdater forceCheckIfItsAnEfficientTimeToUpdateAlbumArt];
                    }
                }
                
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

    __weak MZSongModifierTableView *weakself = self;
    //animate the song name in place
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, updateCellWithAnimationFadeDelay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [weakself beginUpdates];
        [weakself reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                    withRowAnimation:UITableViewRowAnimationFade];
        if(_creatingANewSong){
            if(! [weakself isRowPresentInTableView:0 withSection:1]){
                [weakself insertSections:[NSIndexSet indexSetWithIndex:1]
                    withRowAnimation:UITableViewRowAnimationNone];
            }
        }
        [weakself endUpdates];
        [weakself reloadData];
    });
    
    //add "add to lib" cell in section 2 and scroll to it
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.35 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(weakself && _creatingANewSong){
            [weakself beginUpdates];
            if(_creatingANewSong){
                if(! [weakself isRowPresentInTableView:0 withSection:1]){
                    [weakself insertSections:[NSIndexSet indexSetWithIndex:1]
                            withRowAnimation:UITableViewRowAnimationBottom];
                }
            }
            [weakself endUpdates];
            [weakself scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]
                            atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
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
    
    if(artistName.length == 0)  //was all whitespace, or user gave us an empty string
        return;
    
    if(_songIAmEditing.artist){
        [MZCoreDataModelDeletionService removeSongFromItsArtist:_songIAmEditing];
    }
    
    Artist *newArtist;
    if(_songIAmEditing.album){  //song had album
        if(! _songIAmEditing.album.artist){  //album does NOT have an artist
            newArtist = [Artist createNewArtistWithName:artistName usingAlbum:_songIAmEditing.album inManagedContext:[CoreDataManager context]];
        } else{  //album already has artist, remove this song from the album.
            [MZCoreDataModelDeletionService removeSongFromItsAlbum:_songIAmEditing];
        }
    }
    else
        newArtist = [Artist createNewArtistWithName:artistName inManagedContext:[CoreDataManager context]];
    
    _songIAmEditing.artist = newArtist;
    
    __weak MZSongModifierTableView *weakself = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, updateCellWithAnimationFadeDelay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [weakself beginUpdates];
        [weakself reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]
                    withRowAnimation:UITableViewRowAnimationFade];
        [weakself endUpdates];
        [weakself reloadData];
    });
}

- (void)albumNameCreationCompleteAndSetUpAlbum:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DoneEditingAlbumField" object:nil];
    NSString *albumName = (NSString *)notification.object;
    albumName = [albumName removeIrrelevantWhitespace];
    
    //not checking for some album name because we CAN create albums with the same name!
    if(albumName.length == 0)  //was all whitespace, or user gave us an empty string
        return;
    
    Album *newAlbum = [Album createNewAlbumWithName:albumName usingSong:_songIAmEditing
                                   inManagedContext:[CoreDataManager context]];
    if(_songIAmEditing.album)
    {
        [MZCoreDataModelDeletionService removeSongFromItsAlbum:_songIAmEditing];
    }
    _songIAmEditing.album = newAlbum;
    if(_songIAmEditing.artist){
        newAlbum.artist = _songIAmEditing.artist;
    }
    
    __weak MZSongModifierTableView *weakself = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, updateCellWithAnimationFadeDelay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [weakself beginUpdates];
        [weakself reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]
                    withRowAnimation:UITableViewRowAnimationFade];
        [weakself reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
        [weakself endUpdates];
        [weakself reloadData];
    });
}

#pragma mark - existing album and artist chosen

- (void)existingAlbumHasBeenChosen:(Album *)album
{
    if(_songIAmEditing.album)
    {
        if(! [_songIAmEditing.album.album_id isEqualToString:album.album_id])
            [MZCoreDataModelDeletionService removeSongFromItsAlbum:_songIAmEditing];
    }
    
    _songIAmEditing.album = album;
    if(_songIAmEditing.artist)
    {
        if(! [_songIAmEditing.artist.artist_id isEqualToString:album.artist.artist_id]
           && album.artist != nil)
            [MZCoreDataModelDeletionService removeSongFromItsArtist:_songIAmEditing];
        else
            _songIAmEditing.album.artist = _songIAmEditing.artist;
    }
    
    _songIAmEditing.album.albumArt.isDirty = @YES;
    _songIAmEditing.artist = _songIAmEditing.album.artist;
    
    __weak MZSongModifierTableView *weakself = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, updateCellWithAnimationFadeDelay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [weakself beginUpdates];
        [weakself reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
        [weakself reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
        [weakself endUpdates];
        [weakself reloadData];
    });
}

- (void)existingArtistHasBeenChosen:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"existing artist chosen"]){
        if(_songIAmEditing.artist){
            [MZCoreDataModelDeletionService removeSongFromItsArtist:_songIAmEditing];
        }
        _songIAmEditing.artist = (Artist *)notification.object;

        __weak MZSongModifierTableView *weakself = self;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, updateCellWithAnimationFadeDelay * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            [weakself beginUpdates];
            [weakself reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
            [weakself endUpdates];
            [weakself reloadData];
        });
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
                    [self.VC.navigationController pushViewController:vc animated:YES];
                } else if(_songIAmEditing.artist){  //remove from current artist
                    [MZCoreDataModelDeletionService removeSongFromItsArtist:_songIAmEditing];
                    [MZCoreDataModelDeletionService removeSongFromItsAlbum:_songIAmEditing];
                    _songIAmEditing.artist = nil;
                    _songIAmEditing.album = nil;
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
                    [MZCoreDataModelDeletionService removeSongFromItsAlbum:_songIAmEditing];
                    _songIAmEditing.album = nil;
                    [self reloadData];
                } else{ //choose existing album
                    
                    ExistingAlbumPickerTableViewController *vc;
                    Album *album = _songIAmEditing.album;
                    vc = [[ExistingAlbumPickerTableViewController alloc] initWithCurrentAlbum:album
                                                                 existingEntityPickerDelegate:self];
                    [self.VC.navigationController pushViewController:vc animated:YES];
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
                    ExistingAlbumPickerTableViewController *vc;
                    Album *album = _songIAmEditing.album;
                    vc = [[ExistingAlbumPickerTableViewController alloc] initWithCurrentAlbum:album
                                                                 existingEntityPickerDelegate:self];
                    [self.VC.navigationController pushViewController:vc animated:YES];
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
                    [MZCoreDataModelDeletionService removeSongFromItsAlbum:_songIAmEditing];
                    _songIAmEditing.album = nil;
                    [self reloadData];
                }
                break;
            default:
                break;
        }
    } else if(popup.tag == 3){  //album art
        switch (buttonIndex)
        {
            case 0:
                if(_currentAlbumArt){  //remove art
                    self.currentAlbumArt = nil;
                    _songIAmEditing.albumArt = nil;
                    if(_songIAmEditing.album){
                        _songIAmEditing.album.albumArt.isDirty = [NSNumber numberWithBool:YES];
                    }
                    userReplacedDefaultYoutubeArt = YES;
                }
                else  //chose photo from phone for art
                    [self pickNewAlbumArtFromPhotos];
                
                [self beginUpdates];
                [self reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]]
                            withRowAnimation:UITableViewRowAnimationFade];
                [self endUpdates];
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
    }
}

#pragma mark - Album Art Methods
- (void)pickNewAlbumArtFromPhotos
{
    UIImagePickerController *photoPickerController = [[UIImagePickerController alloc] init];
    photoPickerController.delegate = self;
    //set tint color specifically for this VC so that the cancel buttons are invisible
    photoPickerController.view.tintColor = [UIColor defaultWindowTintColor];
    photoPickerController.navigationBar.barTintColor = [UIColor defaultAppColorScheme];
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *img = [info objectForKey:UIImagePickerControllerOriginalImage];
    if(img == nil)
        [MyAlerts displayAlertWithAlertType:ALERT_TYPE_CannotOpenSelectedImageError];
    self.currentAlbumArt = img;
    
    if(_songIAmEditing.albumArt == nil)
        _songIAmEditing.albumArt = [SongAlbumArt createNewAlbumArtWithUIImage:img
                                                                  withContext:[CoreDataManager context]];
    else
        _songIAmEditing.albumArt.image = [AlbumArtUtilities compressedDataFromUIImage:img];
    userReplacedDefaultYoutubeArt = YES;
    
    if(_songIAmEditing.album){
        _songIAmEditing.album.albumArt.isDirty = [NSNumber numberWithBool:YES];
    }

    [self beginUpdates];
    [self reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]]
                withRowAnimation:UITableViewRowAnimationFade];
    [self endUpdates];
}


#pragma mark - public methods
- (void)cancelEditing
{
    //now reset any context deletions, insertions, blah blah...
    [[CoreDataManager context] rollback];
    [[CoreDataManager context] reset];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SongEditDone" object:nil];
    [self.VC dismissViewControllerAnimated:YES completion:nil];
    [self preDealloc];
}

//this method is only used for ACTUAL editing. Song creation is handled in "didSelectCell..."
- (void)songEditingWasSuccessful
{
    [[CoreDataManager sharedInstance] saveContext]; //saves the context to disk
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SongEditDone" object:nil];
    [self.VC dismissViewControllerAnimated:YES completion:nil];
    [self preDealloc];
}

@end
