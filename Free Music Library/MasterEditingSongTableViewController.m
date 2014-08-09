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
    
    //remove header gap at top of table, and remove some scrolling space under the delete button (update scroll insets too)
    [self.tableView setContentInset:UIEdgeInsetsMake(-32,0,-30,0)];
    [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(-32,0,-30,0)];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
    [imageCache clearDisk];
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
            cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:_songIAmEditing.artist.artistName];
            
        } else if(indexPath.row == 2){  //Album
            cell.textLabel.text = @"Album";
            cell.detailTextLabel.attributedText = [self makeAttrStringGrayUsingString:_songIAmEditing.album.albumName];
            
        } else if(indexPath.row == 3){  //Album Art
            cell.textLabel.text = @"Album Art";
            UIImage *image;
            if(PRODUCTION_MODE)
                image = [AlbumArtUtilities albumArtFileNameToUiImage: _songIAmEditing.albumArtFileName];
            else{
                if(_songIAmEditing.albumArtFileName)
                    image = [UIImage imageNamed:_songIAmEditing.album.albumName];
            }
            image = [AlbumArtUtilities imageWithImage:image scaledToSize:CGSizeMake(58, 58)];
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
        return 66;
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
                                                             name:@"DoneEditingTextField" object:nil];
                
                EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:_songIAmEditing.songName];
                [self.navigationController pushViewController:vc animated:YES];
                break;
            }
            case 1:  //editing artist
            {
                UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel"
                                                     destructiveButtonTitle:nil otherButtonTitles:@"Choose From Existing Artist",
                                                                                                    @"Create New Artist", nil];
                popup.tag = 1;
                [popup showInView:self.navigationController.view];
                _lastTappedRow = 1;
                break;
            }
            case 2:  //editing album
            {
                if(_songIAmEditing.associatedWithAlbum){
                    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel"
                                                         destructiveButtonTitle:nil otherButtonTitles: @"", @"Remove Art", nil];
                    popup.tag = 2;
                    [popup showInView:self.navigationController.view];
                } else{
                    //album picker
                }
                _lastTappedRow = 2;
                break;
            }
            case 3:  //editing album art
            {
                if(! _songIAmEditing.associatedWithAlbum)
                {  //can only edit album art w/ a song that is part of an album IF you edit the album itself.
                    if(_songIAmEditing.albumArtFileName)
                    {
                        UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel"
                                                             destructiveButtonTitle:nil otherButtonTitles: @"Delete Art", @"Choose New Art", nil];
                        popup.tag = 46872596;
                        popup.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
                        [popup showInView:[self.navigationController view]];
                        
                    }
                    else
                    {
                        [self pickNewAlbumArtFromPhotos];
                    }
                }
                else
                    //custom alertview
                    [self launchAlertViewWithDialog];
                
                _lastTappedRow = 3;
                break;
            }
            case 4:  //editing genre
                _lastTappedRow = 4;
                break;
        }
    }
    
    if(indexPath.section == 1){
        if(indexPath.row == 0){
            [_songIAmEditing deleteSong];
            [self dismissViewControllerAnimated:YES completion:nil];
        } else
            return;
    }
}

- (void)songNameEditingComplete:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DoneEditingTextField" object:nil];
    NSString *newName = (NSString *)notification.object;
    newName = [newName removeIrrelevantWhitespace];
    
    if([_songIAmEditing.songName isEqualToString:newName])
        return;
    if(newName.length == 0)  //was all whitespace, or user gave us an empty string
        return;
    
    //changing song name in this case will break link between song and album art file. This is how i keep it in sync...
    if(! _songIAmEditing.associatedWithAlbum){
        UIImage *albumArt = [AlbumArtUtilities albumArtFileNameToUiImage:_songIAmEditing.albumArtFileName];
        [_songIAmEditing removeAlbumArt];
        [_songIAmEditing setAlbumArt:nil];
        _songIAmEditing.songName = newName;
        
        //after song name is changed, NOW we can create the image file on disk, so it has the correct name.
        [_songIAmEditing setAlbumArt:albumArt];  //this creates the image file, names it, and saves it on disk.
    } else
        _songIAmEditing.songName = (NSString *)notification.object;
    
    [self.tableView reloadData];
}

- (IBAction)leftBarButtonTapped:(id)sender  //cancel
{
    //tell MasterSongsTableViewController that it should leave editing mode since song editing has completed.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SongEditDone" object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)rightBarButtonTapped:(id)sender  //save
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SongSavedDuringEdit" object:_songIAmEditing];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SongEditDone" object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIActionSheet methods
- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(popup.tag == 1){
        switch (buttonIndex)
        {
            case 0:
                //do stuff
                break;
            case 1:
                //do stuff
                break;
            default:
                break;
        }
    }else if(popup.tag == 2){
        switch (buttonIndex)
        {
            case 0:
                [self removeAlbumArtFromSongAndDisk];
                break;
            case 1:
                [self pickNewAlbumArtFromPhotos];
                break;
            default:
                break;
        }
    }
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
    for (UIView *subview in actionSheet.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            UILabel *label = button.titleLabel;
            if([label.text isEqualToString:@"Delete Art"])
                [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
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

- (void)removeAlbumArtFromSongAndDisk
{
    [_songIAmEditing removeAlbumArt];
    [self.tableView reloadData];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    [self dismissModalViewControllerAnimated:YES];
    
    //try to delete the album art on disk (if we are replacing it), otherwise this does nothing.
    [_songIAmEditing setAlbumArt:nil];
    [_songIAmEditing setAlbumArt:image];
    
    [self.tableView reloadData];
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
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        return YES;
    }
    else{
        return NO;  //returned when in portrait, or when app is first launching (UIInterfaceOrientationUnknown)
    }
}

#pragma mark - AlertView
- (void)launchAlertViewWithDialog
{
    NSString * msg = @"This song is part of an album in your library. For this reason, you may only edit this artwork when editing the album itself.";
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
    if(buttonIndex == 1)  //segue to album edit (user wants to change album art i guess?)
        NSLog(@"going to album.");
}

@end
