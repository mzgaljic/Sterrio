//
//  QueueViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/5/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "QueueViewController.h"
#import "MZTableViewCell.h"
#import "SongAlbumArt+Utilities.h"

@interface QueueViewController ()
{
    UINavigationBar *navBar;
    UIColor *localAppTintColor;  //specific for this VC (its been made brighter)
    
    MZPlaybackQueue *queue;
    
    //data models
    NSArray *mainQueueSongsComingUp;
    PlaybackContext *mainQueueContext;
    
    NSArray *upNextPlaybackContexts;
    NSArray *upNextSongs;
    
    BOOL skippingToTappedSong;
    UIView *cellBackgroundBlurView;
    UIView *sectionHeaderBackgroundBlurView;
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
    
    skippingToTappedSong = NO;
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

- (void)preDealloc
{
    //implemented to avoid crash (another class assumes this class exists lol.)
}

- (void)dealloc
{
    self.tableView.delegate = nil;
    self.tableView = nil;
    cellBackgroundBlurView = nil;
    sectionHeaderBackgroundBlurView = nil;
    mainQueueContext = nil;
    mainQueueSongsComingUp = nil;
    upNextPlaybackContexts = nil;
    upNextSongs = nil;
    stackController = nil;
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
        cell = [[MZTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
    else
    {
        // If an existing cell is being reused, reset the image to the default until it is populated.
        // Without this code, previous images are displayed against the new people during rapid scrolling.
        cell.imageView.image = [UIImage imageWithColor:[UIColor clearColor] width:cell.frame.size.height height:cell.frame.size.height];
    }
    cell.displayQueueSongsMode = YES;
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
    
    //make the selection style blurred
    if(cellBackgroundBlurView == nil){
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        cellBackgroundBlurView = [[UIVisualEffectView alloc] initWithEffect:effect];
        cellBackgroundBlurView.frame = cell.contentView.bounds;
    }
    [cell setSelectedBackgroundView:cellBackgroundBlurView];

    // Set up other aspects of the cell content.
    Song *song = [self songForIndexPath:indexPath];
    
    //init cell fields
    cell.textLabel.text = song.songName;
    cell.detailTextLabel.attributedText = [self generateDetailLabelAttrStringForSong:song];
    
    if(indexPath.row == 0)
        cell.textLabel.textColor = localAppTintColor;
    else
        cell.textLabel.textColor = [UIColor whiteColor];
    
    cell.isRepresentingAQueuedSong = [self isUpNextSongPresentAtIndexPath:indexPath];
    
    // Store a reference to the current cell that will enable the image to be associated with the correct
    // cell, when the image is subsequently loaded asynchronously.
    objc_setAssociatedObject(cell,
                             &songIndexPathAssociationKey,
                             indexPath,
                             OBJC_ASSOCIATION_RETAIN);
    
    __weak Song *weaksong = song;
    // Queue a block that obtains/creates the image and then loads it into the cell.
    // The code block will be run asynchronously in a last-in-first-out queue, so that when
    // rapid scrolling finishes, the current cells being displayed will be the next to be updated.
    [stackController addBlock:^{
        
        UIImage *albumArt;
        if(weaksong.albumArt){
            albumArt = [weaksong.albumArt imageFromImageData];
        }
        
        // The block will be processed on a background Grand Central Dispatch queue.
        // Therefore, ensure that this code that updates the UI will run on the main queue.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, &songIndexPathAssociationKey);
            if ([indexPath isEqual:cellIndexPath]) {
                // Only set cell image if the cell currently being displayed is the one that actually required this image.
                // Prevents reused cells from receiving images back from rendering that were requested for that cell in a previous life.
                
                __weak UIImage *cellImg = albumArt;
                //calculate how much one length varies from the other.
                int diff = abs((int)albumArt.size.width - (int)albumArt.size.height);
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
    if(section == 0){
        if(mainQueueContext.queueName == nil)
            return @"";
        return [NSString stringWithFormat:@"  %@",mainQueueContext.queueName];
    }
    else
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
    if([AppEnvironmentConstants preferredSongCellHeight]
         < [AppEnvironmentConstants maximumSongCellHeight] - 18)
        headerFontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    else
        headerFontSize = [PreferredFontSizeUtility hypotheticalLabelFontSizeForPreferredSize:[AppEnvironmentConstants maximumSongCellHeight] - 18];
    header.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                            size:headerFontSize];
    
    //making background clear, and then placing a blur view across the entire header (execpt the uilabel)
    if(sectionHeaderBackgroundBlurView == nil){
        view.tintColor = [UIColor clearColor];
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        sectionHeaderBackgroundBlurView = [[UIVisualEffectView alloc] initWithEffect:effect];
        sectionHeaderBackgroundBlurView.frame = view.bounds;
        sectionHeaderBackgroundBlurView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    [view addSubview:sectionHeaderBackgroundBlurView];
    [view bringSubviewToFront:header.textLabel];
    [view sendSubviewToBack:sectionHeaderBackgroundBlurView];
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
    int nowPlayingCount = 0;
    BOOL nowPlayingSongExists = [[NowPlayingSong sharedInstance] nowPlaying] ? YES : NO;
    if(nowPlayingSongExists)
        nowPlayingCount = 1;
    if(upNextSongs.count + mainQueueSongsComingUp.count + nowPlayingCount > 0)
        return 1;
    else
        return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0){
        BOOL nowPlayingSongExists = [[NowPlayingSong sharedInstance] nowPlaying] ? YES : NO;
        NSUInteger numRows;
        if(nowPlayingSongExists)
            numRows = upNextSongs.count + mainQueueSongsComingUp.count +1;
        else
            numRows = upNextSongs.count + mainQueueSongsComingUp.count;
        return numRows;
    } else
        return 0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int minHeight = [AppEnvironmentConstants minimumSongCellHeight];
    int height = [AppEnvironmentConstants preferredSongCellHeight] * 0.80;
    if(height < minHeight)
        height = minHeight;
    
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    skippingToTappedSong = YES;
    
    Song *tappedSong = [self songForIndexPath:indexPath];
    PlaybackContext *tappedSongsContext = [self contextForIndexPath:indexPath];
    if(indexPath.row == 0
       && [[NowPlayingSong sharedInstance] isEqualToSong:tappedSong
                                      compareWithContext:tappedSongsContext])
    {
        [MusicPlaybackController seekToVideoSecond:[NSNumber numberWithInt:0]];
        [MusicPlaybackController resumePlayback];
    }
    else
    {
        if(indexPath.section == 0)
        {
            NSUInteger numRowsInTableBeforeDeletion = [self.tableView numberOfRowsInSection:0];
            NSUInteger numRowsDeleted = 0;
            
            [self.tableView beginUpdates];
            //erase all rows before the tapped one in the tapped section
            NSMutableArray *deletePaths = [NSMutableArray array];
            for(int i = 0; i < indexPath.row; i++){
                [deletePaths addObject:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
                numRowsDeleted++;
            }
            [self.tableView deleteRowsAtIndexPaths:deletePaths
                                  withRowAnimation:UITableViewRowAnimationTop];
            
#warning this method call is broken. needs to be MUCH better.
            [[MZPlaybackQueue sharedInstance] skipOverThisManyQueueSongsEfficiently:numRowsDeleted -1];
            [MusicPlaybackController skipToNextTrack];
            [MusicPlaybackController resumePlayback];
            
            //now need to refresh the model so everything matches up
            mainQueueSongsComingUp = [queue tableViewOptimizedArrayOfMainQueueSongsComingUp];
            mainQueueContext = [queue mainQueuePlaybackContext];
            upNextSongs = [queue tableViewOptimizedArrayOfUpNextSongs];
            upNextPlaybackContexts = [queue tableViewOptimizedArrayOfUpNextSongContexts];
            
            [self.tableView endUpdates];
            
            BOOL atLeast1RowRemainingInTable = (numRowsInTableBeforeDeletion - numRowsDeleted > 0);
            if(atLeast1RowRemainingInTable)
            {
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            }
        }
    }
    skippingToTappedSong = NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

#pragma mark - Tableview datasource helper
- (Song *)songForIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0){
        int row = (int)indexPath.row;
        if(row == 0)
            return [[NowPlayingSong sharedInstance] nowPlaying];
        
        if(! [self isUpNextSongPresentAtIndexPath:indexPath]){
            row -= upNextSongs.count;  //1 is for the main now playing song
            row--;
            return (Song *)mainQueueSongsComingUp[row];
        } else{
            row--;
            return (Song *)upNextSongs[row];
        }
    }
    return nil;
}

- (BOOL)isUpNextSongPresentAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0){
        int row = (int)indexPath.row;
        if(row == 0){
            if([[NowPlayingSong sharedInstance] isFromPlayNextSongs])
                return YES;
            else
                return NO;
        }
        
        row--;  //take into account the now playing song.
        int lastUpNextSongArrayIndex = (int)upNextSongs.count - 1;
        if(row > lastUpNextSongArrayIndex)
            return NO;
        else
            return YES;
    }
    return NO;
}

- (PlaybackContext *)contextForIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0){

        int row = (int)indexPath.row;
        if(! [self isUpNextSongPresentAtIndexPath:indexPath]){
            return mainQueueContext;
        } else{
            //NEED to differentiate between a context being one row (representing one song)
            //and a context in the table representing a bunch of songs from an album, etc.
#warning CRITICAL bug.
            return upNextPlaybackContexts[--row];
        }
    }
    return nil;
}


- (void)newSongsIsLoading
{
    if(skippingToTappedSong)
        return;
    
    if(mainQueueSongsComingUp.count + upNextSongs.count > 0){
#warning would be more efficient to manually delete the relevant objects within these data sources.
        mainQueueSongsComingUp = [queue tableViewOptimizedArrayOfMainQueueSongsComingUp];
        upNextSongs = [queue tableViewOptimizedArrayOfUpNextSongs];
        upNextPlaybackContexts = [queue tableViewOptimizedArrayOfUpNextSongContexts];
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                              withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView endUpdates];
        
        
        [self.tableView beginUpdates];
        //must be in seperate begin and end update block.
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
}

#pragma mark - Rotation status bar methods
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
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
}

- (void)dismissQueueTapped
{
    [self dismissViewControllerAnimated:YES completion:^(){
        [SongPlayerCoordinator setScreenShottingVideoPlayerAllowed:YES];
    }];
}

#pragma mark - Othe stuff
//copy and pasted from AllSongsDataSource.m
- (NSAttributedString *)generateDetailLabelAttrStringForSong:(Song *)aSong
{
    NSString *artistString = aSong.artist.artistName;
    NSString *albumString = aSong.album.albumName;
    if(artistString != nil && albumString != nil){
        NSMutableString *newArtistString = [NSMutableString stringWithString:artistString];
        [newArtistString appendString:@" "];
        
        NSMutableString *entireString = [NSMutableString stringWithString:newArtistString];
        [entireString appendString:albumString];
        
        NSArray *components = @[newArtistString, albumString];
        //NSRange untouchedRange = [entireString rangeOfString:[components objectAtIndex:0]];
        NSRange grayRange = [entireString rangeOfString:[components objectAtIndex:1]];
        
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:entireString];
        
        [attrString beginEditing];
        [attrString addAttribute: NSForegroundColorAttributeName
                           value:[UIColor grayColor]
                           range:grayRange];
        [attrString endEditing];
        return attrString;
        
    } else if(artistString == nil && albumString == nil)
        return nil;
    
    else if(artistString == nil && albumString != nil){
        NSMutableString *entireString = [NSMutableString stringWithString:albumString];
        
        NSArray *components = @[albumString];
        NSRange grayRange = [entireString rangeOfString:[components objectAtIndex:0]];
        
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:entireString];
        
        [attrString beginEditing];
        [attrString addAttribute: NSForegroundColorAttributeName
                           value:[UIColor grayColor]
                           range:grayRange];
        [attrString endEditing];
        return attrString;
        
    } else if(artistString != nil && albumString == nil){
        
        NSMutableString *entireString = [NSMutableString stringWithString:artistString];
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:entireString];
        return attrString;
        
    } else  //case should never happen
        return nil;
}


@end
