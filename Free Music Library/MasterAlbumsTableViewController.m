//
//  MasterAlbumsTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "MasterAlbumsTableViewController.h"

@interface MasterAlbumsTableViewController()
@property (nonatomic, strong) NSMutableArray *albums;
@end

@implementation MasterAlbumsTableViewController
@synthesize albums;
static BOOL PRODUCTION_MODE;

- (NSMutableArray *) results  //for searching tableview?
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
    self.albums = [NSMutableArray arrayWithArray:[Album loadAll]];
    [self.tableView reloadData];
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
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
    [self setUpNavBarItems];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = YES;
}

- (void)setUpNavBarItems
{
    //edit button
    UIBarButtonItem *editButton = self.editButtonItem;
    editButton.action = @selector(editTapped:);
    
    //+ sign...also wire it up to the ibAction "addButtonPressed"
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                  target:self action:@selector(addButtonPressed)];
    NSArray *rightBarButtonItems = [NSArray arrayWithObjects:editButton, addButton, nil];
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;  //place both buttons on the nav bar
}

- (void)editTapped:(id)sender
{
    if(self.editing)
    {
        //leaving editing mode now
        [super setEditing:NO animated:YES];
        [self makeBarButtonGrey:[self.navigationItem.rightBarButtonItems objectAtIndex:1] yes:YES];
    }
    else
    {
        //entering editing mode now
        [super setEditing:YES animated:YES];
        [self makeBarButtonGrey:[self.navigationItem.rightBarButtonItems objectAtIndex:1] yes:NO];
    }
}

-(void)makeBarButtonGrey:(UIBarButtonItem *)barButton yes:(BOOL)show
{
    if (show) {
        barButton.style = UIBarButtonItemStyleBordered;
        barButton.enabled = true;
    } else {
        barButton.style = UIBarButtonItemStylePlain;
        barButton.enabled = false;
        barButton.title = nil;
    }
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.albums.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlbumItemCell" forIndexPath:indexPath];
    // Configure the cell...
    
    Album *album = [self.albums objectAtIndex: indexPath.row];  //get album instance at this index
    
    //init cell fields
    cell.textLabel.attributedText = [AlbumTableViewFormatter formatAlbumLabelUsingAlbum:album];
    if(! [AlbumTableViewFormatter albumNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[AlbumTableViewFormatter nonBoldAlbumLabelFontSize]];
    [AlbumTableViewFormatter formatAlbumDetailLabelUsingAlbum:album andCell:&cell];
    
    CGSize size = [AlbumTableViewFormatter preferredAlbumAlbumArtSize];
    [cell.imageView sd_setImageWithURL:[AlbumArtUtilities albumArtFileNameToNSURL:album.albumArtFileName]
                      placeholderImage:[UIImage imageWithColor:[UIColor clearColor] width:size.width height:size.height]
                               options:SDWebImageCacheMemoryOnly
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                                 cell.imageView.image = image;
                             }];
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
        //obtain object for the deleted album
        Album *album = [self.albums objectAtIndex:indexPath.row];
        
        for(Song *aSong in album.albumSongs){
            if([aSong isEqual:[PlaybackModelSingleton createSingleton].nowPlayingSong]){
                YouTubeMoviePlayerSingleton *singleton = [YouTubeMoviePlayerSingleton createSingleton];
                [[singleton AVPlayer] pause];
                [singleton setAVPlayerInstance:nil];
                [singleton setAVPlayerLayerInstance:nil];
                break;
            }
        }
        
        //delete the object from our data model (which is saved to disk).
        [album deleteAlbum];
        
        //delete album from the tableview data source
        [[self albums] removeObjectAtIndex:indexPath.row];
        
        //delete row from tableView (just the gui)
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [AlbumTableViewFormatter preferredAlbumCellHeight];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //get the index of the tapped album
    UITableView *tableView = self.tableView;
    for(int i = 0; i < self.albums.count; i++){
        UITableViewCell *cell =[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if(cell.selected){
            self.selectedRowIndexValue = i;
            break;
        }
    }
    
    if([[segue identifier] isEqualToString: @"albumItemSegue"]){
        [[segue destinationViewController] setAlbum:self.albums[self.selectedRowIndexValue]];
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

//called when + sign is tapped - selector defined in setUpNavBarItems method!
- (void)addButtonPressed
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"'+' Tapped"
                                                    message:@"This is how you add songs to the library!  :)"
                                                   delegate:nil
                                          cancelButtonTitle:@"Got it"
                                          otherButtonTitles:nil];
    [alert show];
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
        [self setTabBarVisible:NO animated:NO];
        return YES;
    }
    else{
        [self setTabBarVisible:YES animated:NO];
        //fixes a bug when using another viewController with all these "hiding" nav bar features...and returning to this viewController
        self.tabBarController.tabBar.hidden = NO;
        return NO;  //returned when in portrait, or when app is first launching (UIInterfaceOrientationUnknown)
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