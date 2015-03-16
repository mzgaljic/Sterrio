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
    NSArray *fetchRequests;  //used to fetch songs, each fetchRequest corresponds to one sub-queue.
    NSArray *fetchRequestResults;
    NSArray *playingNextSongs;
    UIColor *localAppTintColor;  //specific for this VC (its been made brighter)
}
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation QueueViewController
short const NOW_PLAYING_SECTION_NUM = 0;
short const PLAYING_NEXT_SECTION_NUM = 1;
short const TABLE_SECTION_FOOTER_HEIGHT = 25;
short FETCH_REQUEST_BATCH_SIZE;
/*
#pragma mark - View Controller life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [SongPlayerCoordinator setScreenShottingVideoPlayerAllowed:NO];
    stackController = [[StackController alloc] init];
    localAppTintColor = [[[[UIColor defaultAppColorScheme] lighterColor] lighterColor] lighterColor];
    [self setBatchSize];
    [self preFetchAllSongsWithBatch];
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
        [self.view addSubview:self.tableView];
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([self class]));
}

#pragma mark - fetching songs
- (void)setBatchSize
{
    if([AppEnvironmentConstants preferredSizeSetting] < 3)
        FETCH_REQUEST_BATCH_SIZE = 70;
    else if([AppEnvironmentConstants preferredSizeSetting] >=3){
        FETCH_REQUEST_BATCH_SIZE = 45;
    }
}

- (void)preFetchAllSongsWithBatch
{
    playingNextSongs = [[MZPlaybackQueue sharedInstance] playNextSongs];
    fetchRequests = [[MZPlaybackQueue sharedInstance] arrayOfFetchRequestsMappingToSubsetQueues];
    NSArray *songsFromRequest;
    NSMutableArray *tempArray = [NSMutableArray array];
    for(NSFetchRequest *someRequest in fetchRequests){
        [someRequest setFetchBatchSize:FETCH_REQUEST_BATCH_SIZE];
        songsFromRequest = [[CoreDataManager context] executeFetchRequest:someRequest error:nil];
        [tempArray addObject:songsFromRequest];
    }
    fetchRequestResults = [NSArray arrayWithArray:tempArray];
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
    
    //init cell fields
    cell.textLabel.attributedText = [SongTableViewFormatter formatSongLabelUsingSong:song];
    if(! [SongTableViewFormatter songNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[SongTableViewFormatter nonBoldSongLabelFontSize]];
    [SongTableViewFormatter formatSongDetailLabelUsingSong:song andCell:&cell];
    
    if(indexPath.row == 0 && indexPath.section == NOW_PLAYING_SECTION_NUM){
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
    NSString *headerTitle;
    if(section == NOW_PLAYING_SECTION_NUM)
        headerTitle = @" Now Playing";
    else if(section == PLAYING_NEXT_SECTION_NUM && playingNextSongs.count > 0)
        headerTitle = @" Up Next";
    else{
        int subQueueNumber = ((int)section - PLAYING_NEXT_SECTION_NUM) +1;
        headerTitle = [NSString stringWithFormat:@" Queue number: %i", subQueueNumber];
    }
    return headerTitle;
}

//setting section header background and text color
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    if(section == NOW_PLAYING_SECTION_NUM)
        [header.textLabel setTextColor:localAppTintColor];
    else
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
- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    view.tintColor = [UIColor clearColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return TABLE_SECTION_FOOTER_HEIGHT;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    short staticSectionsCount = 2;
    if(playingNextSongs.count == 0)
        staticSectionsCount = 1;
    int numSubQueues = (int)fetchRequests.count;
    return staticSectionsCount + numSubQueues;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == NOW_PLAYING_SECTION_NUM)
        return 1;
    else if(section == PLAYING_NEXT_SECTION_NUM && playingNextSongs.count > 0)
        return playingNextSongs.count;
    else{
        if(fetchRequests.count > 0){
            if((playingNextSongs.count > 0 && section == PLAYING_NEXT_SECTION_NUM + 1)
               || (playingNextSongs.count == 0 && section == PLAYING_NEXT_SECTION_NUM)){ //first subqueue
                NowPlayingSong *nowPlayingObj = [NowPlayingSong sharedInstance];
                if([nowPlayingObj isEqualToSong:nowPlayingObj.nowPlaying compareWithContext:nil]){
                    //now playing song is NOT in the first sub-queue, its in "playing next" section.
                    //we can return the entire count of the fetch results.
                    
                    NSArray *songs = fetchRequestResults[0];

                    NSUInteger count = songs.count;
                    if(count == NSNotFound)
                        return 0; //some error occured
                    else
                        return count;
                } else{
                    //must figure out exactly how many more songs left to play in the first sub-queue.
                    NSArray *songs = fetchRequestResults[0];

                    if(songs.count > 0){
                        NSUInteger nowPlayingIndex = [songs indexOfObject:[nowPlayingObj nowPlaying]];
                        if(nowPlayingIndex != NSNotFound && songs.count > nowPlayingIndex+1){
                            //more songs to be played from this source (after the now playing song)
                            int lastIndex = (int)songs.count - 1;
                            int numMoreSongsInFirstSubQueue = lastIndex - (int)nowPlayingIndex;
                            return numMoreSongsInFirstSubQueue;
                        } else
                            return 0;
                    } else{
                        return 0;  //weird case...
                    }
                }
                
            } else{
                //now playing song cant be in a subqueue except the first one, so
                //our job is easy here- simply return the size of the entire fetch.
                int sectionNumOfLastSubQueue = (int)fetchRequests.count + 1;
                if(section <= sectionNumOfLastSubQueue){
                    int songsArrayIndexForSection;
                    if(playingNextSongs.count > 0)
                        songsArrayIndexForSection = (int)section - PLAYING_NEXT_SECTION_NUM + 1;
                    else
                        songsArrayIndexForSection = (int)section - PLAYING_NEXT_SECTION_NUM;
                    NSArray *songs = fetchRequestResults[songsArrayIndexForSection];

                    NSUInteger count = songs.count;
                    if(count == NSNotFound)
                        return 0; //some error occured
                    else
                        return count;
                }
                else
                    return 0;  //section does not exist (not this many sub-queues)
            }
        }
        else
            return 0;
    }
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
    //Song *selectedSong = [queueSongs objectAtIndex:indexPath.row];
    //NSLog(@"Tapped song in queue: %@", selectedSong.songName);
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

#pragma mark - Tableview datasource helper
- (Song *)songForIndexPath:(NSIndexPath *)indexPath
{
    
    int row = (int)indexPath.row;
    int section = (int)indexPath.section;
    Song *desiredSong;
    if(indexPath.section == NOW_PLAYING_SECTION_NUM && row == 0)
        desiredSong =  [[NowPlayingSong sharedInstance] nowPlaying];
    else if(indexPath.section == PLAYING_NEXT_SECTION_NUM && playingNextSongs.count > 0)
        desiredSong = playingNextSongs[row];
    else{
        //get song from subqueue!
        
        //need to take special care with the very first subqueue
        if((playingNextSongs.count > 0 && section == PLAYING_NEXT_SECTION_NUM + 1)
           || (playingNextSongs.count == 0 && section == PLAYING_NEXT_SECTION_NUM))
        {
            NowPlayingSong *nowPlayingObj = [NowPlayingSong sharedInstance];
            
            if(! [nowPlayingObj isEqualToSong:nowPlayingObj.nowPlaying compareWithContext:nil])
            {
                //must figure out exactly how many more songs left to play in the first sub-queue.
                NSArray *songs = fetchRequestResults[0];
                if(songs.count > 0)
                {
                    NSUInteger nowPlayingIndex;
                    if([NowPlayingSong sharedInstance].isFromPlayNextSongs)
                        nowPlayingIndex = [songs indexOfObject:[[MZPlaybackQueue sharedInstance] nextSongScheduledForPlaybackInCurrentSubQueue]];
                    else
                        nowPlayingIndex = [songs indexOfObject:[nowPlayingObj nowPlaying]];
                    
                    if(nowPlayingIndex != NSNotFound && songs.count > nowPlayingIndex+1)
                    {
                        //more songs to be played from this source (after the now playing song)
                        int lastIndex = (int)songs.count - 1;
                        int indexOfSongToReturn = (int)nowPlayingIndex + row + 1;  //plus 1 is to not include the now playing
                        if(indexOfSongToReturn <=  lastIndex)
                            return songs[indexOfSongToReturn];
                        else
                            return nil;
                    } else
                        return nil;
                }
                else
                    return nil;
            }
            //otherwise the now playing song is NOT in the first sub-queue, its in "playing next" section.
            //we can just handle it as a normal subqueue further down...
        }
        
        //for all other subqueues...
        int songsArrayIndexForSection;
        if(playingNextSongs.count > 0)
            songsArrayIndexForSection = (int)section - PLAYING_NEXT_SECTION_NUM + 1;
        else
            songsArrayIndexForSection = (int)section - PLAYING_NEXT_SECTION_NUM;
        NSArray *songs = fetchRequestResults[songsArrayIndexForSection];
        if(songsArrayIndexForSection == 0){
            //if we got to this point, the now playing song is in the "playing next" area.
            //that means we shold just get the index of the object as usual, but with an offset
            //offset will be the index of the next song to be played from the first subqueue.
            Song *nextSong = [[MZPlaybackQueue sharedInstance] nextSongScheduledForPlaybackInCurrentSubQueue];
            NSUInteger indexOfNextSongInFirstSubQueue = [songs indexOfObject:nextSong];
            if(row + indexOfNextSongInFirstSubQueue < songs.count)
                desiredSong = (Song *)[songs objectAtIndex:row + indexOfNextSongInFirstSubQueue];
        }
        else
            desiredSong = (Song *)[songs objectAtIndex:row];
    }
    return desiredSong;
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
 */

@end
