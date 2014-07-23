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
    
    //remove header gap at top of table, and remove some scrolling space under the delete button (update scroll insets too)
    [self.tableView setContentInset:UIEdgeInsetsMake(-32,0,-30,0)];
    [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(-32,0,-30,0)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setProductionModeValue];
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
            case 0:
            {
                _lastTappedRow = 0;
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songEditingComplete:)
                                                             name:@"editableCellFinishedEditing" object:nil];
                
                EditableCellTableViewController *vc = [[EditableCellTableViewController alloc] initWithEditingString:_songIAmEditing.songName];
                [self.navigationController pushViewController:vc animated:YES];
                //[self performSegueWithIdentifier:@"editFieldSegue" sender:self];
                break;

            }
            case 1:
                _lastTappedRow = 1;
                break;
            case 2:
                _lastTappedRow = 2;
            case 3:
                _lastTappedRow = 3;
                break;
            case 4:
                _lastTappedRow = 4;
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

- (void)songEditingComplete:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"editableCellFinishedEditing" object:nil];
    
    _songIAmEditing.songName = (NSString *)notification.object;
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString: @"editFieldSegue"]){
        //setup properties in destination view controller
        switch (_lastTappedRow)
        {
            case 0:
            {
                [[segue destinationViewController] setStringUserIsEditing:_songIAmEditing.songName];
                break;
            }
                
            default:
                break;
        }
    }
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

@end
