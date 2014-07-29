//
//  MasterPlaylistTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterPlaylistTableViewController.h"

@interface MasterPlaylistTableViewController ()
@property(nonatomic, strong) NSMutableArray *allPlaylists;
@property(nonatomic, strong) UIAlertView *createPlaylistAlert;
@end

@implementation MasterPlaylistTableViewController
@synthesize allPlaylists = _allPlaylists, createPlaylistAlert = _createPlaylistAlert;
static BOOL PRODUCTION_MODE;

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
    
    //init tableView model
    _allPlaylists = [NSMutableArray arrayWithArray:[Playlist loadAll]];
    [self.tableView reloadData];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    //if coming from these orientations
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight
       || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        self.tabBarController.tabBar.hidden = YES;
    }
    else
        self.tabBarController.tabBar.hidden = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self setProductionModeValue];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    if(! stillInSameTab){  //want to reset the state of our variables only when we pick another tab
        tappedTabBar = YES;
        pushedMoreViews = NO;
        stillInSameTab = YES;
    }
    stillInSameTab = NO;
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
    return _allPlaylists.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PlaylistItemCell" forIndexPath:indexPath];
    // Configure the cell...
    
    Playlist *playlist = [_allPlaylists objectAtIndex: indexPath.row];  //get playlist instance at this index
    
    //init cell fields
    cell.textLabel.attributedText = [PlaylistTableViewFormatter formatPlaylistLabelUsingPlaylist:playlist];
    if(! [PlaylistTableViewFormatter playlistNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[PlaylistTableViewFormatter nonBoldPlaylistLabelFontSize]];
    //playlist doesnt have detail label  :)
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    //could also selectively choose which rows may be deleted here.
    return YES;
}

//editing the tableView items
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){  //user tapped delete on a row
        //obtain object for the deleted playlist
        Playlist *playlist = [_allPlaylists objectAtIndex:indexPath.row];
        
        //delete the object from our data model (which is saved to disk).
        [playlist deletePlaylist];
        
        //delete album from the tableview data source
        [_allPlaylists removeObjectAtIndex:indexPath.row];
        
        //delete row from tableView (just the gui)
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    //now segue to push view where user can view the tapped playlist
   [self performSegueWithIdentifier:@"playlistItemSegue" sender:[_allPlaylists objectAtIndex:(int)indexPath.row]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PlaylistTableViewFormatter preferredPlaylistCellHeight];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    pushedMoreViews = YES;
    stillInSameTab = YES;
    if([[segue identifier] isEqualToString: @"playlistItemSegue"]){
        [[segue destinationViewController] setPlaylist:sender];
    }
}

- (IBAction)addButtonPressed:(id)sender
{
    _createPlaylistAlert = [[UIAlertView alloc] init];
    _createPlaylistAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    _createPlaylistAlert.title = @"New Playlist";
    [_createPlaylistAlert textFieldAtIndex:0].placeholder = @"Name your new playlist";
    _createPlaylistAlert.delegate = self;  //delgate of entire alertView
    [_createPlaylistAlert addButtonWithTitle:@"Cancel"];
    [_createPlaylistAlert addButtonWithTitle:@"Create"];
    [_createPlaylistAlert textFieldAtIndex:0].delegate = self;  //delegate for the textField
    [_createPlaylistAlert textFieldAtIndex:0].returnKeyType = UIReturnKeyDone;
    [_createPlaylistAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView == _createPlaylistAlert){
        if(buttonIndex == 1){
            NSString *playlistName = [alertView textFieldAtIndex:0].text;
            playlistName = [playlistName removeIrrelevantWhitespace];
            
            if(playlistName.length == 0)  //was all whitespace, or user gave us an empty string
                return;
            
            //create the playlist
            Playlist *newPlaylist = [[Playlist alloc] init];
            newPlaylist.playlistName = playlistName;
            [newPlaylist saveTempPlaylistOnDisk];
            
            //now segue to modal view where user can pick songs for this playlist
            [self performSegueWithIdentifier:@"playlistSongItemPickerSegue" sender:self];
        }
        else  //canceled
            return;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)alertTextField
{
    NSString *playlistName = alertTextField.text;
    if(playlistName.length == 0){
        [alertTextField resignFirstResponder];  //dismiss keyboard.
        [_createPlaylistAlert dismissWithClickedButtonIndex:0 animated:YES];  //dismisses alertView
        return NO;
    }
    int numSpaces = 0;
    for(int i = 0; i < playlistName.length; i++){
        if([playlistName characterAtIndex:i] == ' ')
            numSpaces++;
    }
    if(numSpaces == playlistName.length){
        //playlist can't be all whitespace.
        [alertTextField resignFirstResponder];  //dismiss keyboard.
        [_createPlaylistAlert dismissWithClickedButtonIndex:0 animated:YES];  //dismisses alertView
        return NO;
    }
    
    //create the playlist
    Playlist *newPlaylist = [[Playlist alloc] init];
    newPlaylist.playlistName = playlistName;
    [newPlaylist saveTempPlaylistOnDisk];
    
    [alertTextField resignFirstResponder];  //dismiss keyboard.
    [_createPlaylistAlert dismissWithClickedButtonIndex:50 animated:YES];  //dismisses alertView, skip clickedButtonAtIndex method
    
    //now segue to modal view where user can pick songs for this playlist
    [self performSegueWithIdentifier:@"playlistSongItemPickerSegue" sender:self];
    
    return YES;
}

- (void)sidebar:(RNFrostedSidebar *)sidebar didTapItemAtIndex:(NSUInteger)index
{
    if (1){
        [sidebar dismissAnimated:YES];
        if(index == 3){  //settings button
            pushedMoreViews = YES;
            [self performSegueWithIdentifier:@"settingsSegue" sender:self];
        }
    }
}

- (IBAction)expandableMenuSelected:(id)sender
{
    [FrostedSideBarHelper setupAndShowSlideOutMenuUsingdelegate:self];
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

static BOOL tappedTabBar = YES;
static BOOL pushedMoreViews = NO;
static BOOL stillInSameTab = NO;
- (BOOL)prefersStatusBarHidden
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    //coming from portrait?
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        [self setTabBarVisible:YES animated:NO];
        //fixes a bug when using another viewController with all these "hiding" nav bar features...and returning to this viewController
        self.tabBarController.tabBar.hidden = NO;
        return NO;  //returned when in portrait, or when app is first launching (UIInterfaceOrientationUnknown)
    }
    //coming from landscape?
    else{
        if(pushedMoreViews){
            if(orientation == UIInterfaceOrientationPortrait){  //coming back from dismissed view, presenting in portrait
                if([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft || [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight){
                    [self setTabBarVisible:NO animated:NO];
                    return YES;
                }
                [self setTabBarVisible:YES animated:NO];
                return NO;
            }else{
                [self setTabBarVisible:NO animated:NO];
                return YES;
            }
        }
        if(tappedTabBar){
            tappedTabBar = NO;
            return NO;
        }
        else{
            [self setTabBarVisible:NO animated:NO];
             return YES;
        }
    }
}

#pragma mark - Rotation tab bar methods
- (void)setTabBarVisible:(BOOL)visible animated:(BOOL)animated
{
    // bail if the current state matches the desired state
    if ([self tabBarIsVisible] == visible) return;
    
    // get a frame calculation ready
    CGRect frame = self.tabBarController.tabBar.frame;
    CGFloat height = frame.size.height;
    CGFloat offsetY = (visible)? -height : height;
    
    // zero duration means no animation
    CGFloat duration = (animated)? 0.3 : 0.0;
    
    [UIView animateWithDuration:duration animations:^{
        self.tabBarController.tabBar.frame = CGRectOffset(frame, 0, offsetY);
    }];
}

- (BOOL)tabBarIsVisible
{
    return self.tabBarController.tabBar.frame.origin.y < CGRectGetMaxY(self.view.frame);
}

@end
