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
#import "IBActionSheet.h"
#import "SpotlightHelper.h"
#import "CoreDataEntityMappingUtils.h"

@interface MZSongModifierTableView ()
{
    BOOL canShowAddtoLibButton;
    BOOL userReplacedDefaultYoutubeArt;
    UIActivityIndicatorView *spinner;
    IBActionSheet *popup;
    UIColor *defaultDetailTextLabelColor;
}
@property (nonatomic, strong) UIImage *currentAlbumArt;
@property (nonatomic, strong) UIImage *currentSmallAlbumArt;
@property (nonatomic, assign) BOOL creatingANewSong;
@property (nonatomic, assign) BOOL didSaveCoreData;
@property (nonatomic, strong) MZSongModifierTableView *selfRetainCycle;
@end

@implementation MZSongModifierTableView
@synthesize songIAmEditing = _songIAmEditing;
float const MAX_ALBUM_ART_CELL_HEIGHT = 160;
float const updateCellWithAnimationFadeDelay = 0.4;


#pragma mark - Other stuff
- (void)initWasCalled
{
    if(_songIAmEditing == nil && !_userPickingNewYtVideo){
        self.creatingANewSong = YES;
        NSManagedObjectContext *context = [CoreDataManager context];
        _songIAmEditing = [Song createNewSongWithNoNameAndManagedContext:context];
        SongAlbumArt *newArtObj = [SongAlbumArt createNewAlbumArtWithUIImage:nil withContext:context];
        _songIAmEditing.albumArt = newArtObj;
    }
    
    self.delegate = self;
    self.dataSource = self;
    
    [AppEnvironmentConstants setIsBadTimeToMergeEnsemble:YES];
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

- (void)dealloc
{
    [AppEnvironmentConstants setIsBadTimeToMergeEnsemble:NO];
    if(! _userPickingNewYtVideo) {
        //doing this just in case. found a bug once where tab bar was gone after this editor closing.
        [[NSNotificationCenter defaultCenter] postNotificationName:MZHideTabBarAnimated object:@NO];
    }
}

- (void)preDealloc
{
    self.VC = nil;
    self.songIAmEditing = nil;
    self.theDelegate = nil;
    popup = nil;
    defaultDetailTextLabelColor = nil;
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
        
        //calculate how much one length varies from the other (actually needed here and only here.)
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
    int heightOfAlbumArtCell = [PreferredFontSizeUtility recommendedRowHeightForCellWithSingleLabel] * 2;
    if(heightOfAlbumArtCell > MAX_ALBUM_ART_CELL_HEIGHT)
        heightOfAlbumArtCell = MAX_ALBUM_ART_CELL_HEIGHT;
    return  CGSizeMake(heightOfAlbumArtCell - 4, heightOfAlbumArtCell - 4);
}

- (void)provideDefaultAlbumArt:(UIImage *)image
{
    [self setCurrentAlbumArt:image];
}

- (void)viewWillAppear:(BOOL)animated
{
    //change background color of tableview
    self.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.VC.parentViewController.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
}

- (void)viewDidAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)canShowAddToLibraryButton
{
    canShowAddtoLibButton = YES;
    if([self numberOfSections] == 2){
        [self reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    }
}


#pragma mark - Tableview delegate implementations
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if((_creatingANewSong || _userPickingNewYtVideo) && _songIAmEditing.songName.length > 0)
        return 2;
    else
        return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) {  //rows for editing
        return 4;
    }
    
    BOOL showAddToPlaylistCell = (!_userPickingNewYtVideo && _creatingANewSong && _songIAmEditing.songName.length > 0 && canShowAddtoLibButton);
    
    if(section == 1){
        if((_creatingANewSong || _userPickingNewYtVideo) && _songIAmEditing.songName.length > 0) {
            return (showAddToPlaylistCell) ? 2 : 1;
            
        } else if(_creatingANewSong || _userPickingNewYtVideo) {
            return 0;
            
        } else {
            return (showAddToPlaylistCell) ? 2 : 1;
        }
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
        if(cell == nil){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                          reuseIdentifier:cellIdentifier];
        }
        if(defaultDetailTextLabelColor == nil) {
            defaultDetailTextLabelColor = cell.detailTextLabel.textColor;
        }
        
        if(indexPath.row == 0){  //song name
            cell.textLabel.text = @"Song Name";
            
            if(_songIAmEditing.songName){
                NSString *detailLabelValue = nil;
                detailLabelValue = _songIAmEditing.songName;
                cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:detailLabelValue];
                cell.detailTextLabel.textColor = defaultDetailTextLabelColor;
            }
            else{
                cell.detailTextLabel.text = @"name needed";
                cell.detailTextLabel.textColor = [AppEnvironmentConstants appTheme].contrastingTextColor;
            }
            
            cell.accessoryView = [MSCellAccessory accessoryWithType:FLAT_DISCLOSURE_INDICATOR color:[[AppEnvironmentConstants appTheme].mainGuiTint lighterColor]];
            
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
        
        int fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
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
            if(!_userPickingNewYtVideo && _creatingANewSong
               && _songIAmEditing.songName.length > 0 && canShowAddtoLibButton){
                cell.textLabel.text = @"Add to Library";
                cell.textLabel.textColor = [AppEnvironmentConstants appTheme].contrastingTextColor;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                [spinner stopAnimating];
                spinner = nil;
            } else if(_userPickingNewYtVideo && _songIAmEditing.songName > 0) {
                cell.textLabel.text = @"Save";
                cell.textLabel.textColor = [AppEnvironmentConstants appTheme].contrastingTextColor;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                [spinner stopAnimating];
                spinner = nil;
            } else if((_creatingANewSong || _userPickingNewYtVideo)
                      && _songIAmEditing.songName.length > 0){
                //song name provided, but not all video info needed has loaded
                cell.textLabel.text = @"   Loading additional video info...";
                cell.textLabel.textColor = [AppEnvironmentConstants appTheme].contrastingTextColor;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                cell.accessoryView = spinner;
                [spinner startAnimating];
            }
        } else if(indexPath.row == 1) {
            cell.textLabel.text = @"Add to a Playlist";
            cell.textLabel.textColor = [AppEnvironmentConstants appTheme].contrastingTextColor;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    int fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                          size:fontSize];
    
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
        if([SongPlayerCoordinator isPlayerOnScreen] && (_creatingANewSong || _userPickingNewYtVideo)){
            return [SongPlayerCoordinator heightOfMinimizedPlayer] - 10;  //header is always too big lol
        } else
            return 10;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int height = [PreferredFontSizeUtility recommendedRowHeightForCellWithSingleLabel];
    
    if(indexPath.row == 3)  //album art cell
        return height * 2;
    else
        return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if(cell.selectionStyle == UITableViewCellSelectionStyleNone) {
        return;
    }
    
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
                    notificationNameToPost:@"DoneEditingSongField" fullScreen:NO];
                [self.theDelegate pushThisVC:vc];
                break;
            }
            case 1:  //editing artist
            {
                __weak MZSongModifierTableView *weakself = self;
                
                if(! _songIAmEditing.artist){
                    popup = [[IBActionSheet alloc] initWithTitle:@"Artist"
                                                        callback:^(IBActionSheet *actionSheet, NSInteger buttonIndex){
                                                            [weakself handleActionClickWithButtonIndex:buttonIndex];
                                                        } cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:@"Choose Artist", @"New Artist", nil];
                }
                else if(_songIAmEditing.artist){
                    popup = [[IBActionSheet alloc] initWithTitle:@"Artist"
                                                        callback:^(IBActionSheet *actionSheet, NSInteger buttonIndex){
                                                            [weakself handleActionClickWithButtonIndex:buttonIndex];
                                                        } cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:@"Remove From Artist"
                                               otherButtonTitles:@"Choose Different Artist", @"New Artist", @"Rename", nil];
                }
                
                for(UIButton *aButton in popup.buttons){
                    NSString *regularFont = [AppEnvironmentConstants regularFontName];
                    aButton.titleLabel.font = [UIFont fontWithName:regularFont
                                                              size:20];
                }
                [popup setButtonTextColor:[AppEnvironmentConstants appTheme].contrastingTextColor];
                [popup setTitleTextColor:[UIColor darkGrayColor]];
                
                BOOL hasDestructiveButton = (_songIAmEditing.artist != nil);
                if(hasDestructiveButton)
                    [popup setButtonTextColor:[UIColor redColor]
                             forButtonAtIndex:0];
                
                [popup setCancelButtonFont:[UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                                           size:20]];
                [popup setTitleFont:[UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:18]];
                [popup showInView:[UIApplication sharedApplication].keyWindow];
                
                popup.tag = 1;
                _lastTappedRow = 1;
                break;
            }
            case 2:  //editing album
            {
                __weak MZSongModifierTableView *weakself = self;
                
                if(_songIAmEditing.album){
                    popup = [[IBActionSheet alloc] initWithTitle:@"Album"
                                                        callback:^(IBActionSheet *actionSheet, NSInteger buttonIndex){
                                                            [weakself handleActionClickWithButtonIndex:buttonIndex];
                                                        } cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:@"Remove Song From Album"
                                               otherButtonTitles:@"Choose Different Album", @"New Album", @"Rename", nil];
                } else{
                    //album picker
                    popup = [[IBActionSheet alloc] initWithTitle:@"Album"
                                                        callback:^(IBActionSheet *actionSheet, NSInteger buttonIndex){
                                                            [weakself handleActionClickWithButtonIndex:buttonIndex];
                                                        } cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:@"Choose Album", @"New Album", nil];
                }
                
                for(UIButton *aButton in popup.buttons){
                    NSString *regularFont = [AppEnvironmentConstants regularFontName];
                    aButton.titleLabel.font = [UIFont fontWithName:regularFont
                                                              size:20];
                }
                [popup setButtonTextColor:[AppEnvironmentConstants appTheme].contrastingTextColor];
                
                BOOL hasDestructiveButton = (_songIAmEditing.album != nil);
                if(hasDestructiveButton)
                    [popup setButtonTextColor:[UIColor redColor]
                             forButtonAtIndex:0];
                
                [popup setTitleTextColor:[UIColor darkGrayColor]];
                [popup setCancelButtonFont:[UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                                           size:20]];
                [popup setTitleFont:[UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:18]];
                [popup showInView:[UIApplication sharedApplication].keyWindow];
                
                popup.tag = 2;
                _lastTappedRow = 2;
                break;
            }
            case 3:  //editing album art
            {
                __weak MZSongModifierTableView *weakself = self;
                
                if(_currentAlbumArt)  //song already contains album art
                {  //ask to remove art or add new art (photo or safari)
                    popup = [[IBActionSheet alloc] initWithTitle:@"Album Art"
                                                        callback:^(IBActionSheet *actionSheet, NSInteger buttonIndex){
                                                            [weakself handleActionClickWithButtonIndex:buttonIndex];
                                                        } cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:@"Remove Art"
                                               otherButtonTitles:@"Choose Different Photo", @"Search for Art", nil];
                }
                else
                {   //album art not picked yet, dont show option to remove album art
                    popup = [[IBActionSheet alloc] initWithTitle:@"Album Art"
                                                        callback:^(IBActionSheet *actionSheet, NSInteger buttonIndex){
                                                            [weakself handleActionClickWithButtonIndex:buttonIndex];
                                                        } cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:@"Choose Photo", @"Search for Art", nil];
                }
                
                for(UIButton *aButton in popup.buttons){
                    NSString *regularFont = [AppEnvironmentConstants regularFontName];
                    aButton.titleLabel.font = [UIFont fontWithName:regularFont
                                                              size:20];
                }
                [popup setButtonTextColor:[AppEnvironmentConstants appTheme].contrastingTextColor];
                
                BOOL hasDestructiveButton = (_currentAlbumArt != nil);
                if(hasDestructiveButton)
                    [popup setButtonTextColor:[UIColor redColor]
                             forButtonAtIndex:0];
                
                [popup setTitleTextColor:[UIColor darkGrayColor]];
                [popup setCancelButtonFont:[UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                                           size:20]];
                [popup setTitleFont:[UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:18]];
                [popup showInView:[UIApplication sharedApplication].keyWindow];
                
                popup.tag = 3;
                _lastTappedRow = 3;
                break;
            }
        }
    }
    
    if(indexPath.section == 1) {
        if(indexPath.row == 0) {
            if(_creatingANewSong || _userPickingNewYtVideo){
                //keep strong ref to self until we're done saving.
                _selfRetainCycle = self;
                
                [self preSaveSongProcessing];
                [self.theDelegate songSaveInitiated];
                
                NSError *error;
                if ([[CoreDataManager context] save:&error] == NO) {
                    //save failed
                    [MyAlerts displayAlertWithAlertType:ALERT_TYPE_SongSaveHasFailed];
                }
                else
                {
                    //save success
                    if(_creatingANewSong) {
                        [SpotlightHelper addSongToSpotlightIndex:_songIAmEditing];
                    } else {
                        [SpotlightHelper updateSpotlightIndexForSong:_songIAmEditing];
                    }
                    
                    if(! userReplacedDefaultYoutubeArt){
                        [LQAlbumArtBackgroundUpdater downloadHqAlbumArtWhenConvenientForSongId:_songIAmEditing.uniqueId];
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                            [LQAlbumArtBackgroundUpdater forceCheckIfItsAnEfficientTimeToUpdateAlbumArt];
                        });
                    }
                    
                    [AppEnvironmentConstants setIsBadTimeToMergeEnsemble:NO];
                    
                    //now lets go the extra mile and try to merge here.
                    CDEPersistentStoreEnsemble *ensemble = [[CoreDataManager sharedInstance] ensembleForMainContext];
                    if(ensemble.isLeeched)
                    {
                        [ensemble mergeWithCompletion:^(NSError *error) {
                            if(error){
                                if(self.creatingANewSong){
                                    NSLog(@"Saved song (creation mode), but couldnt merge.");
                                } else {
                                    NSLog(@"Saved song (editing mode), but couldnt merge.");
                                }
                            } else{
                                if(self.creatingANewSong){
                                    NSLog(@"Just Merged after saving song (creation mode).");
                                } else {
                                    NSLog(@"Just Merged after saving song (editing mode).");
                                }
                                
                                [AppEnvironmentConstants setLastSuccessfulSyncDate:[[NSDate alloc] init]];
                            }
                        }];
                    }
                }
                
                [self preDealloc];
                _selfRetainCycle = nil;  //allow this class to be deallocated.
                
            }  //end 'creatingNewSong'
        }  //end indexPath.row == 0
        else if(indexPath.row == 1) {
            //keep strong ref to self until we're done saving.
            _selfRetainCycle = self;

            //'Add to a Playlist'
            AddToPlaylistViewController *addToPlaylistVc = [[AddToPlaylistViewController alloc] initWithSong:_songIAmEditing];
            UINavigationController *navVc = [[UINavigationController alloc] initWithRootViewController:addToPlaylistVc];
            UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:addToPlaylistVc action:@selector(dismiss)];
            addToPlaylistVc.navigationItem.leftBarButtonItem = cancelBtn;
            addToPlaylistVc.delegate = self;
            [self.theDelegate pushThisVC:navVc];
        } else {
            return;
        }
    }
}

//Some logic that needs to happen on a Song object before it's saved into core data
- (void)preSaveSongProcessing
{
    if(self.currentAlbumArt){
        _songIAmEditing.albumArt.image = [AlbumArtUtilities compressedDataFromUIImage:self.currentAlbumArt];
    }
    if(userReplacedDefaultYoutubeArt) {
        _songIAmEditing.nonDefaultArtSpecified = @YES;
    }
    
    //marking songs album album-art as dirty because this song was already added into
    //the tableview controllers during the editing process (you just can't see it
    //since this youtube adder VC is blocking everything.) If you don't mark it as
    //dirty before saving and dismissing this vc, then the album art will be missing
    //some stuff and will look incomplete (only 3 of 4 images will show in collage.)
    _songIAmEditing.album.albumArt.isDirty = @YES;
    [self.theDelegate performCleanupBeforeSongIsSaved:_songIAmEditing];
}

#pragma mark - AddToPlaylistCallbackDelegate 
- (void)willSaveSongToPlaylistWithoutAddingToGeneralLib
{
    [self preSaveSongProcessing];
}

- (void)didSaveSongToPlaylistWithoutAddingToGeneralLib
{
    if(! userReplacedDefaultYoutubeArt){
        [LQAlbumArtBackgroundUpdater downloadHqAlbumArtWhenConvenientForSongId:_songIAmEditing.uniqueId];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [LQAlbumArtBackgroundUpdater forceCheckIfItsAnEfficientTimeToUpdateAlbumArt];
        });
    }
    
    _selfRetainCycle = nil;  //allow this class to be deallocated.
}

#pragma mark - Entity (Song, Album, Artist) Editing logic
#pragma mark - Editing text fields and creating new stuff
- (void)songNameEditingComplete:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DoneEditingSongField" object:nil];
    BOOL shouldScrollTableview = [notification.object[1] boolValue];
    NSString *newName = (NSString *)notification.object[0];
    newName = [newName removeIrrelevantWhitespace];
    
    BOOL songHadNameBeforeUpdate = (_songIAmEditing.songName != nil);
    if([_songIAmEditing.songName isEqualToString:newName])
        return;
    if(newName.length == 0){  //was all whitespace, or user gave us an empty string
        if(_creatingANewSong || _userPickingNewYtVideo){
            _songIAmEditing.songName = nil;
            _songIAmEditing.smartSortSongName = nil;
            _songIAmEditing.firstSmartChar = nil;
        }
        if([self isRowPresentInTableView:0 withSection:1]){
            //delete the add to lib section if song name is non-existant.
            [self beginUpdates];
            [self deleteSections:[NSIndexSet indexSetWithIndex:1]
                withRowAnimation:UITableViewRowAnimationMiddle];
            [self endUpdates];
        }
        [self performSelector:@selector(reloadSongNameCell) withObject:nil afterDelay:0.5];
        return;
    }
    
    _songIAmEditing.songName = newName;
    _songIAmEditing.smartSortSongName = [newName regularStringToSmartSortString];
    
    if(_songIAmEditing.smartSortSongName.length == 0) {
        //edge case, if name is something like 'the', dont remove all characters! Keep original name.
        _songIAmEditing.smartSortSongName = newName;
    }
    _songIAmEditing.firstSmartChar = [_songIAmEditing.smartSortSongName substringToIndex:1];

    __weak MZSongModifierTableView *weakself = self;
    //animate the song name in place
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, updateCellWithAnimationFadeDelay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [weakself beginUpdates];
        [weakself reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                    withRowAnimation:UITableViewRowAnimationFade];
        if(_creatingANewSong || _userPickingNewYtVideo){
            if(! [weakself isRowPresentInTableView:0 withSection:1]){
                [weakself insertSections:[NSIndexSet indexSetWithIndex:1]
                        withRowAnimation:UITableViewRowAnimationFade];
            }
        }
        [weakself endUpdates];
        
        //if the new add to lib section was added to the table, scroll to it (if not visible)
        if(shouldScrollTableview
           && ! songHadNameBeforeUpdate
           && [weakself isRowPresentInTableView:0 withSection:1])
        {
            NSArray *indexes = [self indexPathsForVisibleRows];
            BOOL addToLibButtonVisible = NO;
            if(indexes){
                for(NSIndexPath *anIndexPath in indexes){
                    if(anIndexPath.row == 0 && anIndexPath.section == 1){
                        addToLibButtonVisible = YES;
                        break;
                    }
                }
            }
            if(! addToLibButtonVisible){
                CGPoint bottomOffset = CGPointMake(0, self.contentSize.height - self.bounds.size.height + self.contentInset.bottom + [AppEnvironmentConstants navBarHeight]);
                [self setContentOffset:bottomOffset animated:YES];
            }
        }
    });
}

- (void)artistRenamingComplete:(NSNotification *)notif
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DoneRenamingArtist" object:nil];
    NSString *newName = (NSString *)notif.object[0];
    newName = [newName removeIrrelevantWhitespace];
    
    if([_songIAmEditing.artist.artistName isEqualToString:newName])
        return;
    if(newName.length == 0){  //was all whitespace, or user gave us an empty string
        //nothing to do, lets not delete the existing artist. User should explicitly do that.
        return;
    }
    
    _songIAmEditing.artist.artistName = newName;
    _songIAmEditing.artist.smartSortArtistName = [newName regularStringToSmartSortString];

    if(_songIAmEditing.artist.smartSortArtistName.length == 0) {
        //edge case, if name is something like 'the', dont remove all characters! Keep original name.
        _songIAmEditing.artist.smartSortArtistName = newName;
    }
    _songIAmEditing.artist.firstSmartChar = [_songIAmEditing.artist.smartSortArtistName substringToIndex:1];
    
    __weak MZSongModifierTableView *weakself = self;
    //animate the artist name in place
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, updateCellWithAnimationFadeDelay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakself beginUpdates];
        [weakself reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
        [weakself endUpdates];
    });
}

- (void)albumRenamingComplete:(NSNotification *)notif
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DoneRenamingAlbum" object:nil];
    NSString *newName = (NSString *)notif.object[0];
    newName = [newName removeIrrelevantWhitespace];
    
    if([_songIAmEditing.album.albumName isEqualToString:newName])
        return;
    if(newName.length == 0){  //was all whitespace, or user gave us an empty string
        //nothing to do, lets not delete the existing artist. User should explicitly do that.
        return;
    }
    
    _songIAmEditing.album.albumName = newName;
    _songIAmEditing.album.smartSortAlbumName = [newName regularStringToSmartSortString];
    
    if(_songIAmEditing.album.smartSortAlbumName.length == 0) {
        //edge case, if name is something like 'the', dont remove all characters! Keep original name.
        _songIAmEditing.album.smartSortAlbumName = newName;
    }
    _songIAmEditing.album.firstSmartChar = [_songIAmEditing.album.smartSortAlbumName substringToIndex:1];
    
    __weak MZSongModifierTableView *weakself = self;
    //animate the album name in place
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, updateCellWithAnimationFadeDelay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakself beginUpdates];
        [weakself reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
        [weakself endUpdates];
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
    NSString *artistName = notification.object[0];
    artistName = [artistName removeIrrelevantWhitespace];
    
    if(artistName.length == 0)  //was all whitespace, or user gave us an empty string
        return;
    
    Artist *newArtist = [Artist createNewArtistWithName:artistName
                                       inManagedContext:[CoreDataManager context]];
    
    if(_songIAmEditing.artist)
    {
        [MZCoreDataModelDeletionService removeSongFromItsArtist:_songIAmEditing];
    }
    
    if(_songIAmEditing.album)
    {
        if(_songIAmEditing.album.artist)
        {
            //user picked a NEW artist, but songs album is still the same.
            //remove song from album...
            [MZCoreDataModelDeletionService removeSongFromItsAlbum:_songIAmEditing];
        }
        else
            _songIAmEditing.album.artist = newArtist;
    }
    
    _songIAmEditing.artist = newArtist;
    
    
    __weak MZSongModifierTableView *weakself = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, updateCellWithAnimationFadeDelay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [weakself beginUpdates];
        [weakself reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
        [weakself reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
        [weakself endUpdates];
    });
}

- (void)albumNameCreationCompleteAndSetUpAlbum:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DoneEditingAlbumField" object:nil];
    NSString *albumName = notification.object[0];
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
    if(_songIAmEditing.artist)
    {
        _songIAmEditing.album.artist = _songIAmEditing.artist;
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
    });
}

#pragma mark - existing album and artist chosen

- (void)existingAlbumHasBeenChosen:(Album *)album
{
    if(_songIAmEditing.album)
    {
        if(! [_songIAmEditing.album.uniqueId isEqualToString:album.uniqueId])
            [MZCoreDataModelDeletionService removeSongFromItsAlbum:_songIAmEditing];
    }
    
    _songIAmEditing.album = album;
    if(_songIAmEditing.artist)
    {
        if(! [_songIAmEditing.artist.uniqueId isEqualToString:album.artist.uniqueId]
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
    });
}

- (void)existingArtistHasBeenChosen:(Artist *)artist
{
    if(_songIAmEditing.artist)
    {
        if(! [_songIAmEditing.artist.uniqueId isEqualToString:artist.uniqueId])
            [MZCoreDataModelDeletionService removeSongFromItsArtist:_songIAmEditing];
    }
    
    if(_songIAmEditing.album)
    {
        if(_songIAmEditing.album.artist)
        {
            //user picked a NEW artist, but songs album is still the same.
            //remove song from album...
            [MZCoreDataModelDeletionService removeSongFromItsAlbum:_songIAmEditing];
        }
        else
            _songIAmEditing.album.artist = artist;
    }

    _songIAmEditing.artist = artist;
    
    __weak MZSongModifierTableView *weakself = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, updateCellWithAnimationFadeDelay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [weakself beginUpdates];
        [weakself reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
        [weakself reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
        [weakself endUpdates];
    });
}

#pragma mark - IBActionSheet button tap handling
- (void)handleActionClickWithButtonIndex:(NSInteger) buttonIndex
{
    if(popup.tag == 1){  //artist action sheet
        switch (buttonIndex)
        {
            case 0:
            {
                if(! _songIAmEditing.artist){  //add song to an existing artist
                    ExistingArtistPickerTableViewController *vc;
                    Artist *artist = _songIAmEditing.artist;
                    vc = [[ExistingArtistPickerTableViewController alloc] initWithCurrentArtist:artist
                                                                   existingEntityPickerDelegate:self];
                    [self.theDelegate pushThisVC:vc];
                } else if(_songIAmEditing.artist){  //remove from current artist
                    //order of these two calls matters!
                    [MZCoreDataModelDeletionService removeSongFromItsAlbum:_songIAmEditing];
                    [MZCoreDataModelDeletionService removeSongFromItsArtist:_songIAmEditing];
                    _songIAmEditing.artist = nil;
                    _songIAmEditing.album = nil;
                    NSIndexPath *path1 = [NSIndexPath indexPathForRow:1 inSection:0];
                    NSIndexPath *path2 = [NSIndexPath indexPathForRow:2 inSection:0];
                    [self beginUpdates];
                    [self reloadRowsAtIndexPaths:@[path1, path2]
                                withRowAnimation:UITableViewRowAnimationFade];
                    [self endUpdates];
                }
            }
                break;
            case 1:
                if(! _songIAmEditing.artist){
                    //create a new artist
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(artistNameCreationCompleteAndSetUpArtist:)
                                                                 name:@"DoneEditingArtistField" object:nil];
                    BOOL fullscreen = NO;
                    EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:nil
                                                                                                  notificationNameToPost:@"DoneEditingArtistField" fullScreen:fullscreen];
                    [self.theDelegate pushThisVC:vc];
                    
                } else if(_songIAmEditing.artist){//choose different artist
                    ExistingArtistPickerTableViewController *vc;
                    Artist *artist = _songIAmEditing.artist;
                    vc = [[ExistingArtistPickerTableViewController alloc] initWithCurrentArtist:artist
                                                                   existingEntityPickerDelegate:self];
                    
                    [self.theDelegate pushThisVC:vc];
                }
                break;
            case 2:
            {
                if(_songIAmEditing.artist){
                    //create new artist
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(artistNameCreationCompleteAndSetUpArtist:)
                                                                 name:@"DoneEditingArtistField" object:nil];
                    EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:nil
                                                                                                  notificationNameToPost:@"DoneEditingArtistField"
                                                                                                              fullScreen:NO];
                    [self.theDelegate pushThisVC:vc];
                } else
                    break;
            }
            case 3:
            {
                //renaming artist
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(artistRenamingComplete:)
                                                             name:@"DoneRenamingArtist" object:nil];
                EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:_songIAmEditing.artist.artistName
                                                                                              notificationNameToPost:@"DoneRenamingArtist" fullScreen:NO];
                [self.theDelegate pushThisVC:vc];
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
                    NSIndexPath *path1 = [NSIndexPath indexPathForRow:1 inSection:0];
                    NSIndexPath *path2 = [NSIndexPath indexPathForRow:2 inSection:0];
                    [self beginUpdates];
                    [self reloadRowsAtIndexPaths:@[path1, path2]
                                withRowAnimation:UITableViewRowAnimationFade];
                    [self endUpdates];
                } else{ //choose existing album
                    
                    ExistingAlbumPickerTableViewController *vc;
                    Album *album = _songIAmEditing.album;
                    vc = [[ExistingAlbumPickerTableViewController alloc] initWithCurrentAlbum:album
                                                                 existingEntityPickerDelegate:self];
                    [self.theDelegate pushThisVC:vc];
                }
                break;
            case 1:
                if(! _songIAmEditing.album){  //create new album
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumNameCreationCompleteAndSetUpAlbum:)
                                                                 name:@"DoneEditingAlbumField" object:nil];
                    BOOL fullscreen = NO;
                    EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:nil
                                                                                                  notificationNameToPost:@"DoneEditingAlbumField" fullScreen:fullscreen];
                    [self.theDelegate pushThisVC:vc];
                    break;
                } else{  //place in different album (existing album picker)
                    ExistingAlbumPickerTableViewController *vc;
                    Album *album = _songIAmEditing.album;
                    vc = [[ExistingAlbumPickerTableViewController alloc] initWithCurrentAlbum:album
                                                                 existingEntityPickerDelegate:self];
                    [self.theDelegate pushThisVC:vc];
                }
                
                break;
            case 2:
                if(_songIAmEditing.album){  //create new album
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumNameCreationCompleteAndSetUpAlbum:)
                                                                 name:@"DoneEditingAlbumField" object:nil];
                    EditableCellTableViewController *vc;
                    vc = [[EditableCellTableViewController alloc]
                          initWithEditingString:nil
                          notificationNameToPost:@"DoneEditingAlbumField"
                          fullScreen:NO];
                    [self.theDelegate pushThisVC:vc];
                } else{
                    //remove song from album
                    [MZCoreDataModelDeletionService removeSongFromItsAlbum:_songIAmEditing];
                    _songIAmEditing.album = nil;
                    NSIndexPath *path1 = [NSIndexPath indexPathForRow:1 inSection:0];
                    NSIndexPath *path2 = [NSIndexPath indexPathForRow:2 inSection:0];
                    [self beginUpdates];
                    [self reloadRowsAtIndexPaths:@[path1, path2]
                                withRowAnimation:UITableViewRowAnimationFade];
                    [self endUpdates];
                }
                break;
            case 3:
            {
                //rename album
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumRenamingComplete:)
                                                             name:@"DoneRenamingAlbum" object:nil];
                EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:_songIAmEditing.album.albumName
                                                                                              notificationNameToPost:@"DoneRenamingAlbum" fullScreen:NO];
                [self.theDelegate pushThisVC:vc];
                break;
            }
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

- (void)rotateActionSheet
{
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAllowAnimatedContent
                     animations:^{
                         [popup rotateToCurrentOrientation];
                     }
                     completion:nil];
}

#pragma mark - Album Art Methods
- (void)pickNewAlbumArtFromPhotos
{
    UIImagePickerController *photoPickerController = [[UIImagePickerController alloc] init];
    photoPickerController.delegate = self;
    //set tint color specifically for this VC so that the cancel buttons are not invisible
    photoPickerController.view.tintColor = [AppEnvironmentConstants appTheme].contrastingTextColor;
    photoPickerController.navigationBar.barTintColor = [AppEnvironmentConstants appTheme].mainGuiTint;
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
    picker = nil;
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
- (void)newSongNameGuessed:(NSString *)songName
               artistGuess:(NSString *)artistName
                albumGuess:(NSString *)albumName
{
    //does all the heavy logic lifting...updates the gui, everything.
    [self songNameEditingComplete:[NSNotification notificationWithName:@"" object:@[songName, @NO]]];

    Album *existingAlbumGuess = [CoreDataEntityMappingUtils existingAlbumWithName:albumName];
    if(existingAlbumGuess) {
        [self existingAlbumHasBeenChosen:existingAlbumGuess];
    } else {
        NSNotification *notif = [NSNotification notificationWithName:@"" object:@[albumName, @NO]];
        [self albumNameCreationCompleteAndSetUpAlbum:notif];
        
        Artist *existingArtistGuess = [CoreDataEntityMappingUtils existingArtistWithName:artistName];
        if(existingArtistGuess) {
            [self existingArtistHasBeenChosen:existingArtistGuess];
        } else {
            NSNotification *notif = [NSNotification notificationWithName:@"" object:@[artistName, @NO]];
            [self artistNameCreationCompleteAndSetUpArtist:notif];
        }
    }
}

- (void)cancelEditing
{
    //now reset any context deletions, insertions, blah blah...
    [[CoreDataManager context] rollback];
    //CONTEXT RESET IS VERY VERY BAD! dont use...this destorys the current playback queue somehow!
    //simple rollback is sufficient.

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SongEditDone" object:nil];
    if(! _userPickingNewYtVideo) {
        //we dont want to dismiss unless the user is editing an existing song.
        [self.VC dismissViewControllerAnimated:YES completion:nil];
    }
    [self preDealloc];
}

//this method is only used for ACTUAL editing. Song creation is handled in "didSelectCell..."
- (void)songEditingWasSuccessful
{
    [[CoreDataManager sharedInstance] saveContext]; //saves the context to disk
    _didSaveCoreData = YES;
    [SpotlightHelper updateSpotlightIndexForSong:_songIAmEditing];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SongEditDone" object:nil];
    [self.VC dismissViewControllerAnimated:YES completion:nil];
    [self preDealloc];
}

- (void)interfaceIsAboutToRotate
{
    [self performSelector:@selector(rotateActionSheet) withObject:nil afterDelay:0.1];
}

@end
