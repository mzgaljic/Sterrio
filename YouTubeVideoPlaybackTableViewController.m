//
//  YouTubeVideoPlaybackTableViewController.m
//  zTunes
//
//  Created by Mark Zgaljic on 8/7/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "YouTubeVideoPlaybackTableViewController.h"

@interface YouTubeVideoPlaybackTableViewController ()
{
    //part of photo search, picker, and editor...
    UIPopoverController *_popoverController;
    NSDictionary *_photoPayload;
}

@property (nonatomic, strong) UIBarButtonItem *addToLibraryButton;
@property (weak, nonatomic) IBOutlet UINavigationItem *navBar;
@property (nonatomic, strong) XCDYouTubeVideoPlayerViewController *videoPlayerViewController;

@property (nonatomic, assign) BOOL enoughSongInformationGiven;
@property (nonatomic, strong) UIImage *albumArt;
@property (nonatomic, strong) UIImage *smallCellAlbumArt;
@property (nonatomic, strong) NSString *currentUserEnteredSongName;
@property (nonatomic, strong) NSString *currentUserEnteredArtistName;
@property (nonatomic, strong) NSString *currentUserEnteredAlbumName;
@property (nonatomic, strong) NSString *currentUserEnteredGenreName;
@end

@implementation YouTubeVideoPlaybackTableViewController
@synthesize enoughSongInformationGiven = _enoughSongInformationGiven, albumArt = _albumArt;

static BOOL PRODUCTION_MODE;
static const short Landscape_TableView_Header_Offset = 32;
static const short Song_Input_TextField_Tag = 100;
static const short Artist_Input_TextField_Tag = 200;
static const short Album_Input_TextField_Tag = 300;
static const short Genre_Input_TextField_Tag = 400;

- (void)dealloc
{
    [YouTubeVideoSearchService removeDelegate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    numberTimesViewHasBeenShown = 0;
    _addToLibraryButton = nil;
    _ytVideo = nil;
    _albumArt = nil;
    _smallCellAlbumArt = nil;
    _currentUserEnteredSongName = nil;
    _currentUserEnteredGenreName = nil;
    _currentUserEnteredArtistName = nil;
    _currentUserEnteredAlbumName = nil;
    NSLog(@"Dealloc'ed in %@", NSStringFromClass([YouTubeVideoPlaybackTableViewController class]));
}

- (void)setAlbumArt:(UIImage *)albumArt
{
    if(albumArt == nil){
        _albumArt = nil;
        albumArt = nil;
        _smallCellAlbumArt = nil;
        return;
    } else{
        _albumArt = albumArt;
        albumArt = nil;
        _smallCellAlbumArt = [AlbumArtUtilities imageWithImage:_albumArt scaledToSize:CGSizeMake(58, 58)];
        return;
    }
}

- (void)setEnoughSongInformationGiven:(BOOL)enoughSongInformationGiven
{
    _enoughSongInformationGiven = enoughSongInformationGiven;
    if(enoughSongInformationGiven)
        [self makeBarButtonItemNormal:_addToLibraryButton];
    else
        [self makeBarButtonItemGrey:_addToLibraryButton];
}

- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

#pragma mark - Custom Initializer
- (id)initWithYouTubeVideo:(YouTubeVideo *)youtubeVideoObject
{
    UIStoryboard*  sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    YouTubeVideoPlaybackTableViewController* vc = [sb instantiateViewControllerWithIdentifier:@"ytVideoFieldEntryAndVideoPlayer"];
    self = vc;
    if (self) {
        if(youtubeVideoObject == nil)
            return nil;
        _ytVideo = youtubeVideoObject;
        _photoPayload = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[[YouTubeMoviePlayerSingleton createSingleton] AVPlayer] pause];
    //hack to hide back button text. This ALSO changes future back buttons if more stuff is pushed. BEWARE.
    self.navigationController.navigationBar.topItem.title = @"";
    [self setProductionModeValue];
    self.enoughSongInformationGiven = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setUpLockScreenInfoAndArt)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    self.navigationController.toolbarHidden = NO;
    _navBar.title = _ytVideo.videoName;
    _navBar.backBarButtonItem.title = @"";
    [self setUpVideoPlayer];
}

static short numberTimesViewHasBeenShown = 0;
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(numberTimesViewHasBeenShown == 0)
        [self setPlaceHolderImageForVideoPlayer];  //would do this in viewDidLoad but self.view.frame has incorrect values until viewWillAppear
    numberTimesViewHasBeenShown++;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(! self.enoughSongInformationGiven)
        [self setUpAddToLibraryButton];  //only works in viewDidAppear.
    
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
    self.navigationController.navigationBar.translucent = NO;

    [[[YouTubeMoviePlayerSingleton createSingleton] previewMusicYoutubePlayer] pause];
    [[YouTubeMoviePlayerSingleton createSingleton] previewMusicYoutubePlayer].initialPlaybackTime = -1;
    [[[YouTubeMoviePlayerSingleton createSingleton] previewMusicYoutubePlayer] stop];
    [[YouTubeMoviePlayerSingleton createSingleton] previewMusicYoutubePlayer].initialPlaybackTime = -1;
    [[[YouTubeMoviePlayerSingleton createSingleton] previewMusicYoutubePlayer].view removeFromSuperview];
    [[YouTubeMoviePlayerSingleton createSingleton] setPreviewMusicYouTubePlayerInstance: nil];
}

#pragma mark - Setting up ALMoviePlayerController
- (void)setUpVideoPlayer
{
    //unnecessary to get video id info twice. remove this if time permits.
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:_ytVideo.videoId completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
        if (video)
        {
            BOOL allowedToPlayVideo = NO;  //not checking if we can physically play, but legally (apples 10 minute streaming rule)
            BOOL usingWifi = NO;
            Reachability *reachability = [Reachability reachabilityForInternetConnection];
            [reachability startNotifier];
            NetworkStatus status = [reachability currentReachabilityStatus];
            if (status == ReachableViaWiFi){
                //WiFi
                allowedToPlayVideo = YES;
                usingWifi = YES;
            }
            else if (status == ReachableViaWWAN)
            {
                //3G
                if(video.duration >= 600)  //user cant watch video longer than 10 minutes without wifi
                    allowedToPlayVideo = NO;
                else
                    allowedToPlayVideo = YES;
            }
            if(allowedToPlayVideo){
                //find video quality closest to setting preferences
                NSDictionary *vidQualityDict = video.streamURLs;
                NSURL *url;
                if(usingWifi){
                    short maxDesiredQuality = [AppEnvironmentConstants preferredWifiStreamSetting];
                    url =[YouTubeMoviePlayerSingleton closestUrlQualityMatchForSetting:maxDesiredQuality usingStreamsDictionary:vidQualityDict];
                }else{
                    short maxDesiredQuality = [AppEnvironmentConstants preferredCellularStreamSetting];
                    url =[YouTubeMoviePlayerSingleton closestUrlQualityMatchForSetting:maxDesiredQuality usingStreamsDictionary:vidQualityDict];
                }
                
                //Now that we have the url, load the video into our MPMoviePlayerController
                [self setUpVideoView];
                
            }
            else{
                NSString *title = @"Long Video Without Wifi";
                NSString *msg = @"Sorry, playback of long videos (ie: more than 10 minutes) is restricted to Wifi.";
                [self launchAlertViewWithDialogUsingTitle:title andMessage:msg];
            }
        }
        else
        {
            // Handle error
            NSString *title = @"Trouble Loading Video";
            NSString *msg = @"Sorry, something whacky is going on, please try again.";
            [self launchAlertViewWithDialogUsingTitle:title andMessage:msg];
        }
    }];
    
    _videoPlayerViewController = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:_ytVideo.videoId];
}

- (void)setUpVideoView
{
    [MRProgressOverlayView dismissAllOverlaysForView:self.tableView.tableHeaderView animated:YES];
    float widthOfScreenRoationIndependant;
    float  a = [[UIScreen mainScreen] bounds].size.height;
    float b = [[UIScreen mainScreen] bounds].size.width;
    if(a < b)
        widthOfScreenRoationIndependant = a;
    else
        widthOfScreenRoationIndependant = b;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    int offset = 0;
    if(orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft)
        offset += Landscape_TableView_Header_Offset;
    float frameHeight = [self videoHeightInSixteenByNineAspectRatioGivenWidth:widthOfScreenRoationIndependant];
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, frameHeight + offset)];
    [self.tableView.tableHeaderView setFrame:CGRectMake(0, 0, headerView.frame.size.width, headerView.frame.size.height)];
    self.tableView.tableHeaderView = headerView;
    
    //present this MPMoviePlayerController inside of the headerView of the table
	self.tableView.tableHeaderView.frame = CGRectMake(0.f, 0.f, headerView.bounds.size.width, headerView.bounds.size.height);
	self.tableView.tableHeaderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [_videoPlayerViewController presentInView:self.tableView.tableHeaderView];
    [_videoPlayerViewController.moviePlayer play];
    
    YouTubeMoviePlayerSingleton *singleton = [YouTubeMoviePlayerSingleton createSingleton];
    [singleton setPreviewMusicYouTubePlayerInstance:_videoPlayerViewController.moviePlayer];
}

- (void)setPlaceHolderImageForVideoPlayer
{
    float widthOfScreenRoationIndependant;
    float  a = [[UIScreen mainScreen] bounds].size.height;
    float b = [[UIScreen mainScreen] bounds].size.width;
    if(a < b)
        widthOfScreenRoationIndependant = a;
    else
        widthOfScreenRoationIndependant = b;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    int offset = 0;
    if(orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft)
        offset += Landscape_TableView_Header_Offset;
    float frameHeight = [self videoHeightInSixteenByNineAspectRatioGivenWidth:widthOfScreenRoationIndependant];
    UIView *placeHolderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, frameHeight + offset)];
    [placeHolderView setBackgroundColor:[UIColor colorWithPatternImage:
                        [UIImage imageWithColor:[UIColor clearColor] width:placeHolderView.frame.size.width height:placeHolderView.frame.size.height]]];
    
    [MRProgressOverlayView showOverlayAddedTo:placeHolderView title:@"" mode:MRProgressOverlayViewModeIndeterminateSmall animated:YES];
    self.tableView.tableHeaderView = placeHolderView;
}

#pragma mark - AlertView
- (void)launchAlertViewWithDialogUsingTitle:(NSString *)aTitle andMessage:(NSString *)aMessage
{
    SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:aTitle
                                                      message:aMessage
                                                     delegate:self
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    
    alert.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    alert.messageLabelFont = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize]];
    alert.suggestedButtonFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    [alert show];
}

- (void)alertView:(SDCAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)
        [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Memory warning
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
}

#pragma mark - Lock Screen Song Info & Art
- (void)setUpLockScreenInfoAndArt
{
    [SDWebImageDownloader.sharedDownloader downloadImageWithURL:[NSURL URLWithString:_ytVideo.videoThumbnailUrlHighQuality]
                                                        options:0
                                                       progress:^(NSInteger receivedSize, NSInteger expectedSize)
     // progression tracking code
     {
     }
                                                      completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished)
     {
         if (image && finished)
         {
             // do something with image
             Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
             if (playingInfoCenter) {
                 NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
                 
                 MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage: image];
                 
                 [songInfo setObject:_ytVideo.videoName forKey:MPMediaItemPropertyTitle];
                 //[songInfo setObject:@"song Artist" forKey:MPMediaItemPropertyArtist];
                 //[songInfo setObject:@"song Album" forKey:MPMediaItemPropertyAlbumTitle];
                 [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
                 [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
             }
         }
     }];
}

#pragma mark - 16:9 Aspect ratio helper
- (float)videoHeightInSixteenByNineAspectRatioGivenWidth:(float)width
{
    float tempVar = width;
    tempVar = width * 9.0f;
    return tempVar / 16.0f;
}

#pragma mark - Toolbar methods
- (void)addToLibraryButtonTapped
{
    #warning code does not take genre into account yet
    if(_enoughSongInformationGiven){
        //create song and if necessary, the albums artists, etc here.
        
        BOOL artistName = NO, albumName = NO, genreName = NO;
        if(_currentUserEnteredArtistName.length > 0)
            artistName = YES;
        if(_currentUserEnteredAlbumName.length > 0)
            albumName = YES;
        if(_currentUserEnteredGenreName.length > 0)
            genreName = YES;
        
        if(!artistName && !albumName)  //just song name given
            [self createSongWithName:_currentUserEnteredSongName];
        
        else if(artistName && !albumName)  //song and artist names given
            [self createSongWithName:_currentUserEnteredSongName byArtistName:_currentUserEnteredArtistName];
        
        else if(!artistName && albumName)  //song and album names given
            [self createSongWithName:_currentUserEnteredSongName partOfAlbumNamed:_currentUserEnteredAlbumName];
        
        else if(artistName && albumName)  //song, album, and artist names given
            [self createSongWithName:_currentUserEnteredSongName
                        byArtistName:_currentUserEnteredArtistName
                    partOfAlbumNamed:_currentUserEnteredAlbumName];
    }
    
    [[[YouTubeMoviePlayerSingleton createSingleton] previewMusicYoutubePlayer] pause];
    [[YouTubeMoviePlayerSingleton createSingleton] setPreviewMusicYouTubePlayerInstance: nil];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)setUpAddToLibraryButton
{
    _addToLibraryButton = [[UIBarButtonItem alloc] initWithTitle:@"Add To Library"
                                                           style:UIBarButtonItemStyleDone
                                                          target:self
                                                          action:@selector(addToLibraryButtonTapped)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    [self makeBarButtonItemGrey:_addToLibraryButton];
    [self.navigationController.toolbar setItems:@[flexibleSpace, _addToLibraryButton] animated:YES];
}

- (void)makeBarButtonItemGrey:(UIBarButtonItem *)barButton
{
    barButton.style = UIBarButtonItemStylePlain;
    barButton.enabled = false;
}

- (void)makeBarButtonItemNormal:(UIBarButtonItem *)barButton
{
    barButton.style = UIBarButtonItemStyleDone;
    barButton.enabled = true;
}

#pragma mark - TableView delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if(indexPath.section == 4){  //album art cell
        cell = [tableView dequeueReusableCellWithIdentifier:@"SongAlbumArtEntryFieldCell" forIndexPath:indexPath];
        if([AppEnvironmentConstants boldNames])
            cell.textLabel.font = [UIFont boldSystemFontOfSize:20.0];
        else
            cell.textLabel.font = [UIFont systemFontOfSize:20.0];
        cell.textLabel.text = @"Album Art";
        cell.accessoryView = [[UIImageView alloc] initWithImage:_smallCellAlbumArt];
        cell.detailTextLabel.text = @" ";
        return cell;
    }
   
    cell = [tableView dequeueReusableCellWithIdentifier:@"SongEntryFieldCell" forIndexPath:indexPath];

    // Configure the cell...
    UITextField * txtField = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height)];
    txtField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    txtField.autoresizesSubviews = YES;
    txtField.layer.cornerRadius = 10.0;
    [txtField setBorderStyle:UITextBorderStyleRoundedRect];
    
    switch (indexPath.section) {
        case 0:
            [txtField setPlaceholder:@"Song"];
            txtField.tag = Song_Input_TextField_Tag;
            if(_currentUserEnteredSongName.length > 0)
                txtField.text = _currentUserEnteredSongName;
            break;
        case 1:
            [txtField setPlaceholder:@"Artist"];
            txtField.tag = Artist_Input_TextField_Tag;
            if(_currentUserEnteredArtistName.length > 0)
                txtField.text = _currentUserEnteredArtistName;
            break;
        case 2:
            [txtField setPlaceholder:@"Album"];
            txtField.tag = Album_Input_TextField_Tag;
            if(_currentUserEnteredAlbumName.length > 0)
                txtField.text = _currentUserEnteredAlbumName;
            break;
        case 3:
            [txtField setPlaceholder:@"Genre"];
            txtField.tag = Genre_Input_TextField_Tag;
            if(_currentUserEnteredGenreName.length > 0)
                txtField.text = _currentUserEnteredGenreName;
            break;
        default:
            break;
    }
    
    if([AppEnvironmentConstants boldNames])
        txtField.font = [UIFont boldSystemFontOfSize:20.0];
    else
        txtField.font = [UIFont systemFontOfSize:20.0];
    txtField.returnKeyType = UIReturnKeyDone;
    txtField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [txtField setDelegate:self];

    cell.accessoryType = UITableViewCellAccessoryNone;
    [cell addSubview:txtField];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.section == 4)
        if(indexPath.row == 0)
            [self showActionSheet];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if(section == 4)
        return @"All fields optional, except 'Song Name'";
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return (section == 4) ? 32.0f : 0.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:     return 6.0f;
        case 1:
        case 2:
        case 3:     return 14.0f;
        case 4:     return 34.0f;  //album art section
        default:    return 14.0f;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 4) ? 66.0f : 50.0f;
}

#pragma mark - Album art helper stuff (Action Sheet, Photo picker, etc.)
- (void)showActionSheet
{
    UIActionSheet *actionSheet;
    if(_albumArt == nil){
        actionSheet = [[UIActionSheet alloc] initWithTitle:@"Album Art" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose Photo", @"Search for Art", nil];
    } else
        actionSheet = [[UIActionSheet alloc] initWithTitle:@"Album Art" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Art" otherButtonTitles:@"Edit Art", @"Take Photo", @"Choose Photo", @"Search for Art", nil];
    
    [actionSheet showInView:self.navigationController.view];
    [[[YouTubeMoviePlayerSingleton createSingleton] previewMusicYoutubePlayer] pause];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(_albumArt == nil)
    {
        switch (buttonIndex) {
            case 0:  //take photo tapped
                [NSTimer scheduledTimerWithTimeInterval: 0.5f
                                                 target:self
                                               selector:@selector(showCameraViewController)
                                               userInfo:nil
                                                repeats:NO];
                break;
            case 1:  //chose photo tapped
                [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                break;
            case 2:  //search tapped
            {
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"x-web-search://?%@",
                                                   [[self buildAlbumArtSearchString] stringForHTTPRequest]]];
                
                if (![[UIApplication sharedApplication] openURL:url])
                    NSLog(@"%@%@",@"Failed to open url:",[url description]);
#warning display 'failed to open safari' warning to user
                break;
            }
                
            case 3:  //cancel tapped
                break;
            default:
                break;
        }
    }
    else
    {
        switch (buttonIndex) {
            case 0:  //delete album art
                self.albumArt = nil;
                [self.tableView reloadData];
                break;
            case 1:  //edit album art
                [self presentPhotoEditor];
                break;
            case 2:  //take photo tapped
                [NSTimer scheduledTimerWithTimeInterval: 0.5f
                                                 target:self
                                               selector:@selector(showCameraViewController)
                                               userInfo:nil
                                                repeats:NO];
                break;
            case 3:  //chose photo tapped
                [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                break;
            case 4:  //search tapped
            {
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"x-web-search://?%@",
                                                   [[self buildAlbumArtSearchString] stringForHTTPRequest]]];
                
                if (![[UIApplication sharedApplication] openURL:url])
                    NSLog(@"%@%@",@"Failed to open url:",[url description]);
#warning display 'failed to open safari' warning to user
                    break;
            }
            case 5:  //cancel tapped
                break;
            default:
                break;
        }
    }
}

- (void)showCameraViewController
{
    [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera];
}

- (NSString *)buildAlbumArtSearchString
{
    NSMutableString *albumArtSearchTerm = [NSMutableString stringWithString:@""];
    if(_currentUserEnteredAlbumName != nil)
        [albumArtSearchTerm appendString: _currentUserEnteredAlbumName];
    [albumArtSearchTerm appendString:@" "];
    
    if(_currentUserEnteredArtistName != nil)
        [albumArtSearchTerm appendString: _currentUserEnteredArtistName];
    [albumArtSearchTerm appendString:@" "];
    
    if(_currentUserEnteredSongName != nil && (_currentUserEnteredAlbumName == nil))
        [albumArtSearchTerm appendString: _currentUserEnteredSongName];
    [albumArtSearchTerm appendString:@" "];
    
    albumArtSearchTerm = [NSMutableString stringWithString:[albumArtSearchTerm removeIrrelevantWhitespace]];
    [albumArtSearchTerm appendString:@" album art"];
    return albumArtSearchTerm;
}

- (void)presentPhotoPickerWithImage:(UIImage *)image
{
    DZNPhotoPickerController *picker = nil;
    if (image && _photoPayload) {
        picker = [[DZNPhotoPickerController alloc] initWithEditableImage:image];
        picker.cropMode = [[_photoPayload objectForKey:DZNPhotoPickerControllerCropMode] integerValue];
    }
    picker.finalizationBlock = ^(DZNPhotoPickerController *picker, NSDictionary *info) {
        [self updateImageWithPayload:info];
        [picker dismissViewControllerAnimated:YES completion:NULL];
    };
    
    picker.failureBlock = ^(DZNPhotoPickerController *picker, NSError *error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"An Error has occured", nil)
                                                        message:error.localizedDescription
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
    };
    
    picker.cancellationBlock = ^(DZNPhotoPickerController *picker) {
        [picker dismissViewControllerAnimated:YES completion:NULL];
    };
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)presentPhotoEditor
{
    UIImage *image = [_photoPayload objectForKey:UIImagePickerControllerOriginalImage];
    [self presentPhotoPickerWithImage:image];
}

- (void)updateImageWithPayload:(NSDictionary *)payload
{
    _photoPayload = payload;
    UIImage *image = [payload objectForKey:UIImagePickerControllerEditedImage];
    if (!image)
        image = [payload objectForKey:UIImagePickerControllerOriginalImage];
    
    //add album art to cell
    self.albumArt = image;
    [self.tableView reloadData];
}

- (void)presentImagePickerWithSourceType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.allowsEditing = YES;
    picker.cropMode = DZNPhotoEditorViewControllerCropModeSquare;
    
    picker.finalizationBlock = ^(UIImagePickerController *picker, NSDictionary *info) {
        [self handleImagePicker:picker withMediaInfo:info];
    };
    
    picker.cancellationBlock = ^(UIImagePickerController *picker) {
        [self dismissController:picker];
    };
    
    [self presentController:picker];
}

- (void)handleImagePicker:(UIImagePickerController *)picker withMediaInfo:(NSDictionary *)info
{
    if (picker.cropMode != DZNPhotoEditorViewControllerCropModeNone) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        
        DZNPhotoEditorViewController *editor = [[DZNPhotoEditorViewController alloc] initWithImage:image cropMode:picker.cropMode];
        [picker pushViewController:editor animated:YES];
    }
    else {
        [self updateImageWithPayload:info];
        [self dismissController:picker];
    }
}

- (void)presentController:(UIViewController *)controller
{
    [self presentViewController:controller animated:YES completion:NULL];
}

- (void)dismissController:(UIViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UITextField methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    NSString *string = [textField.text removeIrrelevantWhitespace];
    if(string.length == 0){
        textField.text = @"";
        if(textField.tag == Song_Input_TextField_Tag)
            self.enoughSongInformationGiven = NO;
        return YES;
    }
    
    switch (textField.tag) {
        case Song_Input_TextField_Tag:      self.enoughSongInformationGiven = YES;
                                            _currentUserEnteredSongName = textField.text;
                                            break;
            
        case Artist_Input_TextField_Tag:    _currentUserEnteredArtistName = textField.text;
                                            break;
            
        case Album_Input_TextField_Tag:     _currentUserEnteredAlbumName = textField.text;
                                            break;
            
        case Genre_Input_TextField_Tag:     _currentUserEnteredGenreName = textField.text;
                                            break;
        default:    break;
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSString *string = [textField.text removeIrrelevantWhitespace];
    if(string.length == 0){
        textField.text = @"";
        if(textField.tag == Song_Input_TextField_Tag)
            self.enoughSongInformationGiven = NO;
    }
    
    switch (textField.tag) {
        case Song_Input_TextField_Tag:      self.enoughSongInformationGiven = YES;
            _currentUserEnteredSongName = textField.text;
            break;
            
        case Artist_Input_TextField_Tag:    _currentUserEnteredArtistName = textField.text;
            break;
            
        case Album_Input_TextField_Tag:     _currentUserEnteredAlbumName = textField.text;
            break;
            
        case Genre_Input_TextField_Tag:     _currentUserEnteredGenreName = textField.text;
            break;
        default:    break;
    }
}


#pragma mark - Song, Album, Artist, and Genre 'factories' (not real factory)
- (void)createSongWithName:(NSString *)songName
{
    Song *myNewSong;
    myNewSong = [Song createNewSongWithName:songName
                       inNewOrExistingAlbum:nil
                      byNewOrExistingArtist:nil
                                    inGenre:0
                           inManagedContext:[CoreDataManager context]];
    myNewSong.youtube_id = _ytVideo.videoId;
    [myNewSong setAlbumArt:self.albumArt];
    
    [[CoreDataManager sharedInstance] saveContext];
    NSString *videoId = myNewSong.youtube_id;
#warning register for the notification: DataManagerDidSaveFailedNotification  (look in CoreDataManager.m)
}

- (void)createSongWithName:(NSString *)songName byArtistName:(NSString *)artistName
{
    Song *myNewSong;
    myNewSong = [Song createNewSongWithName:songName
                       inNewOrExistingAlbum:nil
                      byNewOrExistingArtist:artistName
                                    inGenre:0
                           inManagedContext:[CoreDataManager context]];
    myNewSong.youtube_id = _ytVideo.videoId;
    [myNewSong setAlbumArt:self.albumArt];
    
    [[CoreDataManager sharedInstance] saveContext];
#warning register for the notification: DataManagerDidSaveFailedNotification  (look in CoreDataManager.m)
}

- (void)createSongWithName:(NSString *)songName partOfAlbumNamed:(NSString *)albumName
{
    Song *myNewSong;
    myNewSong = [Song createNewSongWithName:songName
                       inNewOrExistingAlbum:albumName
                      byNewOrExistingArtist:nil
                                    inGenre:0
                           inManagedContext:[CoreDataManager context]];
    myNewSong.youtube_id = _ytVideo.videoId;
    [myNewSong setAlbumArt:self.albumArt];
    
    [[CoreDataManager sharedInstance] saveContext];
#warning register for the notification: DataManagerDidSaveFailedNotification  (look in CoreDataManager.m)
}

- (void)createSongWithName:(NSString *)songName byArtistName:(NSString *)artistName partOfAlbumNamed:(NSString *)albumName
{
    Song *myNewSong;
    myNewSong = [Song createNewSongWithName:songName
                       inNewOrExistingAlbum:albumName
                      byNewOrExistingArtist:artistName
                                    inGenre:0
                           inManagedContext:[CoreDataManager context]];
    myNewSong.youtube_id = _ytVideo.videoId;
    [myNewSong setAlbumArt:self.albumArt];
    
    [[CoreDataManager sharedInstance] saveContext];
#warning register for the notification: DataManagerDidSaveFailedNotification  (look in CoreDataManager.m)
}


#pragma mark - Rotation methods
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    UIView *headerView = self.tableView.tableHeaderView;
    CGRect newRect;
    if(toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
        newRect = CGRectMake(0, 0, self.view.frame.size.width, headerView.frame.size.height + Landscape_TableView_Header_Offset);
    else
        newRect = CGRectMake(0, 0, self.view.frame.size.width, headerView.frame.size.height - Landscape_TableView_Header_Offset);
    
    // Animate the height change of the headerView
    [UIView animateWithDuration:0.5 animations:^{
        headerView.frame = newRect;
        self.tableView.tableHeaderView = headerView;
    }];
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // only iOS 7 methods, check http://stackoverflow.com/questions/18525778/status-bar-still-showing
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}


@end
