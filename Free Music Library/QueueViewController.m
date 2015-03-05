//
//  QueueViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "QueueViewController.h"

@interface QueueViewController ()
{
    UINavigationBar *navBar;
    NSArray *queueSongs;
}
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation QueueViewController

#pragma mark - View Controller life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [SongPlayerCoordinator setScreenShottingVideoPlayerAllowed:NO];
    queueSongs = [MusicPlaybackController listOfUpcomingSongsInQueueIncludeNowPlaying:YES];
    stackController = [[StackController alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setUpCustomNavBar];
    
    if(self.tableView == nil){
        int y = [AppEnvironmentConstants navBarHeight] + [AppEnvironmentConstants statusBarHeight];
        int navBarHeight = [AppEnvironmentConstants navBarHeight];
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                                       y,
                                                                       self.view.frame.size.width,
                                                                       self.view.frame.size.height - navBarHeight)];
        self.tableView.backgroundColor = [UIColor clearColor];
        [self.tableView setSeparatorColor:[UIColor whiteColor]];
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
        [self.view addSubview:self.tableView];
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView reloadData];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([self class]));
}

#pragma mark - Custom Nav Bar
- (void)setUpCustomNavBar
{
    int y = [AppEnvironmentConstants statusBarHeight];
    int vcWidth = self.view.frame.size.width;
    int navBarHeight = [AppEnvironmentConstants navBarHeight];
    navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, y, vcWidth, navBarHeight)];
    [self.view addSubview:navBar];
    
    //make nav bar transparent, let blurred one show through.
    [navBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    navBar.shadowImage = [UIImage new];
    navBar.translucent = YES;
    self.view.backgroundColor = [UIColor clearColor];
    navBar.backgroundColor = [UIColor clearColor];
    
    UIBarButtonItem *closeBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"UIButtonBarArrowDown"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(dismissQueueTapped)];
    
    UINavigationItem *navigItem = [[UINavigationItem alloc] initWithTitle:@"Playback Queue"];
    navigItem.leftBarButtonItem = closeBtn;
    navBar.items = @[navigItem];
}

#pragma mark - Table View Data Source
static char songIndexPathAssociationKey;  //used to associate cells with images when scrolling
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"SongQueueItemCell";
    MZTableViewCell *cell = (MZTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
        cell = [[MZTableViewCell alloc] init];
    else
    {
        // If an existing cell is being reused, reset the image to the default until it is populated.
        // Without this code, previous images are displayed against the new people during rapid scrolling.
        cell.imageView.image = [UIImage imageWithColor:[UIColor clearColor] width:cell.frame.size.height height:cell.frame.size.height];
    }
    
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
    
    // Set up other aspects of the cell content.
    Song *song = [queueSongs objectAtIndex:indexPath.row];
    
    //init cell fields
    cell.textLabel.attributedText = [SongTableViewFormatter formatSongLabelUsingSong:song];
    if(! [SongTableViewFormatter songNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[SongTableViewFormatter nonBoldSongLabelFontSize]];
    [SongTableViewFormatter formatSongDetailLabelUsingSong:song andCell:&cell];
    if(indexPath.row == 0){
        cell.textLabel.textColor = [[[[UIColor defaultAppColorScheme] lighterColor] lighterColor] lighterColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.userInteractionEnabled = NO;
    }
    else{
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.userInteractionEnabled = YES;
    }
    
    // Store a reference to the current cell that will enable the image to be associated with the correct
    // cell, when the image is subsequently loaded asynchronously.
    objc_setAssociatedObject(cell,
                             &songIndexPathAssociationKey,
                             indexPath,
                             OBJC_ASSOCIATION_RETAIN);
    
    // Queue a block that obtains/creates the image and then loads it into the cell.
    // The code block will be run asynchronously in a last-in-first-out queue, so that when
    // rapid scrolling finishes, the current cells being displayed will be the next to be updated.
    [stackController addBlock:^{
        UIImage *albumArt = [UIImage imageWithData:[NSData dataWithContentsOfURL:
                                                    [AlbumArtUtilities albumArtFileNameToNSURL:song.albumArtFileName]]];
        if(albumArt == nil) //see if this song has an album. If so, check if it has art.
            if(song.album != nil)
                albumArt = [UIImage imageWithData:[NSData dataWithContentsOfURL:
                                                   [AlbumArtUtilities albumArtFileNameToNSURL:song.album.albumArtFileName]]];
        // The block will be processed on a background Grand Central Dispatch queue.
        // Therefore, ensure that this code that updates the UI will run on the main queue.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, &songIndexPathAssociationKey);
            if ([indexPath isEqual:cellIndexPath]) {
                // Only set cell image if the cell currently being displayed is the one that actually required this image.
                // Prevents reused cells from receiving images back from rendering that were requested for that cell in a previous life.
                
                __weak UIImage *cellImg = albumArt;
                //calculate how much one length varies from the other.
                int diff = abs(albumArt.size.width - albumArt.size.height);
                if(diff > 10){
                    //image is not a perfect (or close to perfect) square. Compensate for this...
                    cellImg = [albumArt imageScaledToFitSize:cell.imageView.frame.size];
                }
                [UIView transitionWithView:cell.imageView
                                  duration:MZCellImageViewFadeDuration
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    cell.imageView.image = cellImg;
                                } completion:nil];
            }
        });
    }];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)
        return queueSongs.count;
    else
        return 0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [SongTableViewFormatter preferredSongCellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Song *selectedSong = [queueSongs objectAtIndex:indexPath.row];
    NSLog(@"Tapped song in queue: %@", selectedSong.songName);
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

#pragma mark - Rotation status bar methods
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    float widthOfScreenRoationIndependant;
    float heightOfScreenRotationIndependant;
    float  a = [[UIScreen mainScreen] bounds].size.height;
    float b = [[UIScreen mainScreen] bounds].size.width;
    if(a < b)
    {
        heightOfScreenRotationIndependant = b;
        widthOfScreenRoationIndependant = a;
    }
    else
    {
        widthOfScreenRoationIndependant = b;
        heightOfScreenRotationIndependant = a;
    }
    
    if(toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft
       || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight){
        int y = 0;
        int vcWidth = heightOfScreenRotationIndependant;
        int vcHeight = widthOfScreenRoationIndependant;
        //smaller landscape nav bar
        int navBarHeight = [AppEnvironmentConstants navBarHeight] - 4;
        navBar.frame = CGRectMake(0, y, vcWidth, navBarHeight);
        
        self.tableView.frame = CGRectMake(0,
                                          navBarHeight,
                                          vcWidth,
                                          vcHeight - navBarHeight);
    } else{
        int y = [AppEnvironmentConstants statusBarHeight];
        int vcWidth = widthOfScreenRoationIndependant;
        int vcHeight = heightOfScreenRotationIndependant;
        int navBarHeight = [AppEnvironmentConstants navBarHeight];
        navBar.frame = CGRectMake(0, y, vcWidth, navBarHeight);
        
        y = [AppEnvironmentConstants navBarHeight] + [AppEnvironmentConstants statusBarHeight];
        self.tableView.frame = CGRectMake(0,
                                          y,
                                          vcWidth,
                                          vcHeight - navBarHeight);
    }
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)dismissQueueTapped
{
    [self dismissViewControllerAnimated:YES completion:^(){
        [SongPlayerCoordinator setScreenShottingVideoPlayerAllowed:YES];
    }];
}

@end
