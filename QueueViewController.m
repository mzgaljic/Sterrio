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
#import "PlayableItem.h"
#import "PlaylistItem.h"
#import "AllSongsDataSource.h"

@interface QueueViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MZPlaybackQueueSnapshot *snapshot;
@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic, strong) UIView *cellBackgroundBlurView;
@property (nonatomic, strong) UIView *sectionHeaderBackgroundBlurView;
@end

@implementation QueueViewController : UIViewController
short const TABLE_SECTION_FOOTER_HEIGHT = 25;
short const UP_NEXT_SONGS_SECTION = 2;

#pragma mark - View Controller life cycle
- (id)initWithPlaybackQueueSnapshot:(MZPlaybackQueueSnapshot *)snapshot
{
    if(self = [super init]) {
        _snapshot = snapshot;
    }
    return nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    stackController = [[StackController alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewSongLoading)
                                                 name:MZNewSongLoading
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setUpCustomNavBar];
    
    if(self.tableView == nil) {
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

//FYI: another class assumes this method exists so don't delete this method.
- (void)preDealloc
{
    _tableView.delegate = nil;
    _tableView = nil;
    _snapshot = nil;
    _navBar = nil;
    _cellBackgroundBlurView = nil;
    _sectionHeaderBackgroundBlurView = nil;
    stackController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([self class]));
}

#pragma mark - Custom Nav Bar
- (void)setUpCustomNavBar
{
    int y = [AppEnvironmentConstants statusBarHeight];
    int vcWidth = self.view.frame.size.width;
    int navBarHeight = [AppEnvironmentConstants navBarHeight];
    _navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, y, vcWidth, navBarHeight)];
    
    //this VC has a very dark theme, make nav bar buttons and text white.
    _navBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    _navBar.tintColor = [UIColor whiteColor];
    [self.view addSubview:_navBar];
    
    //make nav bar transparent, let blurred one show through.
    [_navBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    _navBar.shadowImage = [UIImage new];
    _navBar.translucent = YES;
    self.view.backgroundColor = [UIColor clearColor];
    _navBar.backgroundColor = [UIColor clearColor];
    
    UIImage *arrowDownImg = [UIImage imageNamed:@"UIButtonBarArrowDown"];
    UIBarButtonItem *closeBtn = [[UIBarButtonItem alloc] initWithImage:arrowDownImg
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(dismissQueueTapped)];
    
    UINavigationItem *navigItem = [[UINavigationItem alloc] initWithTitle:@"Playback Queue"];
    navigItem.leftBarButtonItem = closeBtn;
    _navBar.items = @[navigItem];
}

#pragma mark - Table View Data Source
static char songIndexPathAssociationKey;  //used to associate cells with images when scrolling
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"SongQueueItemCell";
    MZTableViewCell *cell = (MZTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[MZTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
    }
    
    cell.imageView.image = [UIImage imageWithColor:[UIColor clearColor]
                                             width:cell.frame.size.height
                                            height:cell.frame.size.height];
    cell.displayQueueSongsMode = YES;
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
    
    //make the selection style blurred
    if(_cellBackgroundBlurView == nil){
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        _cellBackgroundBlurView = [[UIVisualEffectView alloc] initWithEffect:effect];
        _cellBackgroundBlurView.frame = cell.contentView.bounds;
    }
    [cell setSelectedBackgroundView:_cellBackgroundBlurView];

    // Set up other aspects of the cell content.
    PlayableItem *item = [self itemForIndexPath:indexPath];
    Song *song = item.songForItem;
    
    //init cell fields
    cell.textLabel.text = song.songName;
    cell.detailTextLabel.text = [AllSongsDataSource generateLabelStringForSong:song];
    
    if(indexPath.row == 0) {
        cell.textLabel.textColor = [[[AppEnvironmentConstants appTheme].mainGuiTint lighterColor] lighterColor];
        cell.isRepresentingANowPlayingItem = YES;
    } else {
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.isRepresentingANowPlayingItem = NO;
    }
    
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
        __block UIImage *albumArt;
        if(weaksong){
            NSString *artObjId = weaksong.albumArt.uniqueId;
            if(artObjId){
                
                //this is a background queue. get the object (image blob) on background context!
                NSManagedObjectContext *context = [CoreDataManager stackControllerThreadContext];
                [context performBlockAndWait:^{
                    albumArt = [weaksong.albumArt imageFromImageData];
                }];
                
                if(albumArt == nil) {
                    albumArt = [UIImage imageNamed:@"Sample Album Art"];
                }
            }
        }
        
        // The block will be processed on a background Grand Central Dispatch queue.
        // Therefore, ensure that this code that updates the UI will run on the main queue.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, &songIndexPathAssociationKey);
            if ([indexPath isEqual:cellIndexPath]) {
                // Only set cell image if the cell currently being displayed is the one that actually required this image.
                // Prevents reused cells from receiving images back from rendering that were requested for that cell in a previous life.
                [UIView transitionWithView:cell.imageView
                                  duration:MZCellImageViewFadeDuration
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    cell.imageView.image = albumArt;
                                } completion:nil];
            }
        });
    }];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    //if(section == 0 && mainQueueContext.queueName != nil){
      //  return [NSString stringWithFormat:@"  %@",mainQueueContext.queueName];
    //}
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
       < [AppEnvironmentConstants maximumSongCellHeight] - 18) {
        headerFontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    } else {
        headerFontSize = [PreferredFontSizeUtility hypotheticalLabelFontSizeForPreferredSize:[AppEnvironmentConstants maximumSongCellHeight] - 18];
    }
    header.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                            size:headerFontSize];
    
    //making background clear, and then placing a blur view across the entire header (execpt the uilabel)
    if(_sectionHeaderBackgroundBlurView == nil) {
        view.tintColor = [UIColor clearColor];
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _sectionHeaderBackgroundBlurView = [[UIVisualEffectView alloc] initWithEffect:effect];
        _sectionHeaderBackgroundBlurView.frame = view.bounds;
        _sectionHeaderBackgroundBlurView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    [view addSubview:_sectionHeaderBackgroundBlurView];
    [view bringSubviewToFront:header.textLabel];
    [view sendSubviewToBack:_sectionHeaderBackgroundBlurView];
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
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self itemArrayForSection:section].count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PreferredFontSizeUtility recommendedRowHeightForCellWithSingleLabel] * 1.2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
#warning implementation needed
    //PlayableItem *tappedItem = [self itemForIndexPath:indexPath];
    //[MusicPlaybackController seekToVideoSecond:[NSNumber numberWithInt:0]];
    //[MusicPlaybackController resumePlayback];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

#pragma mark - Tableview datasource helper
- (PlayableItem *)itemForIndexPath:(NSIndexPath *)indexPath
{
    return [[self itemArrayForSection:indexPath.section] objectAtIndex:indexPath.row];
}

- (NSArray *)itemArrayForSection:(NSUInteger)section
{
    switch (section) {
        case 0: {
            return _snapshot.historySongs;
        }
        case 1: {
            PlayableItem *item = [[NowPlaying sharedInstance] playableItem];
            return (item == nil) ? @[] : @[item];
        }
        case 2: {
            return _snapshot.upNextQueuedSongs;
        }
        case 3: {
            return _snapshot.futureSongs;
        }
        default:
            NSLog(@"switch statement is missing case %lu.", (unsigned long)section);
            @throw NSInternalInconsistencyException;
            break;
    }
}

- (BOOL)isUpNextSongPresentAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == UP_NEXT_SONGS_SECTION;
}

- (void)handleNewSongLoading
{
    
}

#pragma mark - Rotation status bar methods
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    float widthOfScreenRoationIndependant;
    float heightOfScreenRotationIndependant;
    float  a = [[UIScreen mainScreen] bounds].size.height;
    float b = [[UIScreen mainScreen] bounds].size.width;
    if(a < b) {
        heightOfScreenRotationIndependant = b;
        widthOfScreenRoationIndependant = a;
    } else {
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
        _navBar.frame = CGRectMake(0, y, vcWidth, navBarHeight);
        
        self.tableView.frame = CGRectMake(0, navBarHeight, vcWidth, vcHeight - navBarHeight);
    } else {
        int y = [AppEnvironmentConstants statusBarHeight];
        int vcWidth = widthOfScreenRoationIndependant;
        int vcHeight = heightOfScreenRotationIndependant;
        int navBarHeight = [AppEnvironmentConstants navBarHeight];
        _navBar.frame = CGRectMake(0, y, vcWidth, navBarHeight);
        
        y = [AppEnvironmentConstants navBarHeight] + [AppEnvironmentConstants statusBarHeight];
        self.tableView.frame = CGRectMake(0, y, vcWidth, vcHeight - navBarHeight);
    }
}

- (void)dismissQueueTapped
{
    [self preDealloc];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
