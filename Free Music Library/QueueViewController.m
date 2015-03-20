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
    UIColor *localAppTintColor;  //specific for this VC (its been made brighter)
    short UP_NEXT_SECTION_NUM;
    short MAIN_QUEUE_SECTION_NUM;
    MZPlaybackQueue *queue;
    BOOL needToUpdateDataModels;
    
    //data models
    NSArray *mainQueueSongsComingUp;
    PlaybackContext *mainQueueContext;
    
    NSArray *upNextPlaybackContexts;
    NSArray *upNextSongs;
}
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation QueueViewController : UIViewController
short const TABLE_SECTION_FOOTER_HEIGHT = 25;
short const SECTION_EMPTY = -1;

#pragma mark - View Controller life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    needToUpdateDataModels = YES;
    [SongPlayerCoordinator setScreenShottingVideoPlayerAllowed:NO];
    stackController = [[StackController alloc] init];
    localAppTintColor = [[[UIColor defaultAppColorScheme] lighterColor] lighterColor];
    
    queue = [MZPlaybackQueue sharedInstance];
    mainQueueSongsComingUp = [queue tableViewOptimizedArrayOfMainQueueSongsComingUp];
    mainQueueContext = [queue mainQueuePlaybackContext];
    upNextSongs = [queue tableViewOptimizedArrayOfUpNextSongs];
    upNextPlaybackContexts = [queue tableViewOptimizedArrayOfUpNextSongContexts];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newSongsIsLoading)
                                                 name:MZNewSongLoading
                                               object:nil];
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
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
        self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        [self.view addSubview:self.tableView];
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)dealloc
{
    self.tableView.delegate = nil;
    self.tableView = nil;
    mainQueueContext = nil;
    mainQueueSongsComingUp = nil;
    upNextPlaybackContexts = nil;
    upNextSongs = nil;
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
    
    //make the selection style blurred
    UIVisualEffectView *blurEffectView;
    blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    blurEffectView.frame = cell.contentView.bounds;
    [cell setSelectedBackgroundView:blurEffectView];

    // Set up other aspects of the cell content.
    Song *song = [self songForIndexPath:indexPath];
    PlaybackContext *songContext = [self contextForIndexPath:indexPath];
    
    //init cell fields
    cell.textLabel.attributedText = [SongTableViewFormatter formatSongLabelUsingSong:song];
    if(! [SongTableViewFormatter songNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[SongTableViewFormatter nonBoldSongLabelFontSize]];
    [SongTableViewFormatter formatSongDetailLabelUsingSong:song andCell:&cell];
    
    if([[NowPlayingSong sharedInstance] isEqualToSong:song compareWithContext:songContext]
       && indexPath.row == 0){
        cell.textLabel.textColor = localAppTintColor;
    }
    else{
        cell.textLabel.textColor = [UIColor whiteColor];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    [self updateSectionNumsBasedOnQueueData];
    if(section == UP_NEXT_SECTION_NUM){
        return @"  Queued Songs";
    } else if(section == MAIN_QUEUE_SECTION_NUM){
        return [NSString stringWithFormat:@"  %@",mainQueueContext.queueName];
    } else
        return @"";
}

//setting section header background and text color
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view
       forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor whiteColor]];
    header.textLabel.backgroundColor = [UIColor clearColor];
    int headerFontSize;
    if([AppEnvironmentConstants preferredSizeSetting] < 5)
        headerFontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    else
        headerFontSize = [PreferredFontSizeUtility hypotheticalLabelFontSizeForPreferredSize:5];
    header.textLabel.font = [UIFont systemFontOfSize:headerFontSize];
    
    //making background clear, and then placing a blur view across the entire header (execpt the uilabel)
    UIVisualEffectView *blurEffectView;
    view.tintColor = [UIColor clearColor];
    blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    blurEffectView.frame = view.bounds;
    blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [view addSubview:blurEffectView];
    
    [view bringSubviewToFront:header.textLabel];
    [view sendSubviewToBack:blurEffectView];
}

//setting footer header background (using footer view to pad between sections in this case)
- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view
       forSection:(NSInteger)section
{
    view.tintColor = [UIColor clearColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return TABLE_SECTION_FOOTER_HEIGHT;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    [self updateSectionNumsBasedOnQueueData];
    short sectionCount = 0;
    if(UP_NEXT_SECTION_NUM != SECTION_EMPTY)
        sectionCount++;
    if(MAIN_QUEUE_SECTION_NUM != SECTION_EMPTY)
        sectionCount++;
    return sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    [self updateSectionNumsBasedOnQueueData];
    if(section == UP_NEXT_SECTION_NUM){
        return upNextSongs.count;
    } else if(section == MAIN_QUEUE_SECTION_NUM){
        return mainQueueSongsComingUp.count;
    } else
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
    NSUInteger numSectionsBeforeTap = [self numberOfSectionsInTableView:self.tableView];
    
    Song *tappedSong = [self songForIndexPath:indexPath];
    PlaybackContext *tappedSongsContext = [self contextForIndexPath:indexPath];
    if([[NowPlayingSong sharedInstance] isEqualToSong:tappedSong
                                   compareWithContext:tappedSongsContext]){
        [MusicPlaybackController seekToVideoSecond:[NSNumber numberWithInt:0]];
        [MusicPlaybackController resumePlayback];
    } else{
        NowPlayingSong *nowPlayingObj = [NowPlayingSong sharedInstance];
        
        //was a queued song tapped or a main queue song tapped?
        if(indexPath.section == MAIN_QUEUE_SECTION_NUM){
            if(nowPlayingObj.isFromPlayNextSongs)
                [queue skipForward];
            [MusicPlaybackController newQueueWithSong:tappedSong withContext:tappedSongsContext];
        }
        else if(indexPath.section == UP_NEXT_SECTION_NUM){
            
            //skip as many of the queued songs as needed...
            NSUInteger numSongsShouldBeSkipped;
            if(indexPath.row == 0){
                if(nowPlayingObj.isFromPlayNextSongs)
                    numSongsShouldBeSkipped = 1;
                else
                    numSongsShouldBeSkipped = 1;
            }
            if(nowPlayingObj.isFromPlayNextSongs){
                numSongsShouldBeSkipped = indexPath.row;
                for(int i = 0; i < numSongsShouldBeSkipped; i++)
                    [queue skipForward];
                Song *previousSong = [nowPlayingObj nowPlaying];
                [VideoPlayerWrapper startPlaybackOfSong:tappedSong
                                           goingForward:YES
                                                oldSong:previousSong];
            }
            else{
                [MusicPlaybackController skipToNextTrack];
            }
        }
        
        //model needs updating! (will do lazy loading)
        needToUpdateDataModels = YES;
        [self updateSectionNumsBasedOnQueueData];
        
        /*
        //now update table
        [self.tableView beginUpdates];
        NSUInteger numSections = [self numberOfSectionsInTableView:self.tableView];
        if(numSectionsBeforeTap == numSections){
            for(int section = 0; section < numSections; section++){
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        } else{
            //an entire section will be deleted
            if(MAIN_QUEUE_SECTION_NUM == 0){
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0]
                              withRowAnimation:UITableViewRowAnimationTop];
            } else{
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1]
                              withRowAnimation:UITableViewRowAnimationTop];
            }
        }
        
        [self.tableView endUpdates];
         */
        [self.tableView reloadData];
#warning add fancy animations at a later time.
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

#pragma mark - Tableview datasource helper
- (Song *)songForIndexPath:(NSIndexPath *)indexPath
{
    [self updateSectionNumsBasedOnQueueData];
    if(indexPath.section == MAIN_QUEUE_SECTION_NUM){
        return (Song *)mainQueueSongsComingUp[indexPath.row];
    } else if(indexPath.section == UP_NEXT_SECTION_NUM){
        return (Song *)upNextSongs[indexPath.row];
    } else
        return nil;
}

- (PlaybackContext *)contextForIndexPath:(NSIndexPath *)indexPath
{
    [self updateSectionNumsBasedOnQueueData];
    if(indexPath.section == MAIN_QUEUE_SECTION_NUM){
        return mainQueueContext;
    } else if(indexPath.section == UP_NEXT_SECTION_NUM){
        NSUInteger row = indexPath.row;
        return upNextPlaybackContexts[row];
    } else
        return nil;
}

- (void)updateSectionNumsBasedOnQueueData
{
    if(! needToUpdateDataModels)
        return;
    needToUpdateDataModels = NO;
    
    upNextSongs = [queue tableViewOptimizedArrayOfUpNextSongs];
    upNextPlaybackContexts = [queue tableViewOptimizedArrayOfUpNextSongContexts];
    mainQueueSongsComingUp = [queue tableViewOptimizedArrayOfMainQueueSongsComingUp];
    mainQueueContext = [queue mainQueuePlaybackContext];
    
    if(upNextSongs.count > 0)
        UP_NEXT_SECTION_NUM = 0;
    else
        UP_NEXT_SECTION_NUM = SECTION_EMPTY;
    if(mainQueueSongsComingUp.count > 0){
        if(UP_NEXT_SECTION_NUM != SECTION_EMPTY)
            MAIN_QUEUE_SECTION_NUM = 1;
        else
            MAIN_QUEUE_SECTION_NUM = 0;
    } else
        MAIN_QUEUE_SECTION_NUM = SECTION_EMPTY;
}

- (void)newSongsIsLoading
{
#warning need to delete a row somewhere to get rid of the finished song from the list.
    needToUpdateDataModels = YES;
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
