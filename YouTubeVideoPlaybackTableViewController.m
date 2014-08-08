//
//  YouTubeVideoPlaybackTableViewController.m
//  zTunes
//
//  Created by Mark Zgaljic on 8/7/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "YouTubeVideoPlaybackTableViewController.h"

@interface YouTubeVideoPlaybackTableViewController ()
@property (nonatomic, strong) UIBarButtonItem *addToLibraryButton;
@property (weak, nonatomic) IBOutlet UINavigationItem *navBar;

@property (nonatomic, assign) BOOL enoughSongInformationGiven;
@property (nonatomic, strong) UIImage *albumArt;
@end

@implementation YouTubeVideoPlaybackTableViewController
@synthesize enoughSongInformationGiven = _enoughSongInformationGiven;
static BOOL PRODUCTION_MODE;
static const short Landscape_TableView_Header_Offset = 32;
static const short Song_Input_TextField_Tag = 100;
static const short Artist_Input_TextField_Tag = 200;
static const short Album_Input_TextField_Tag = 300;
static const short Genre_Input_TextField_Tag = 400;

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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setProductionModeValue];
    self.enoughSongInformationGiven = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setUpLockScreenInfoAndArt)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    self.navigationController.toolbarHidden = NO;
    self.navigationController.navigationBar.translucent = YES;
    _navBar.title = _ytVideo.videoName;
    _navBar.backBarButtonItem.title = @"";
    [self setUpVideoPlayer];
    
    NSError *setCategoryError = nil;
    NSError *activationError = nil;
    [[AVAudioSession sharedInstance] setActive:YES error:&activationError];
    [[AVAudioSession sharedInstance] setDelegate:self];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
}

static short numberTimesViewHasBeenShown = 0;
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(numberTimesViewHasBeenShown == 0)
        [self setPlaceHolderImageForVideoPlayer];  //would do this in viewDidLoad but self.view.frame has incorrect values until viewWillAppear
    //Once the view has loaded then we can register to begin recieving controls and we can become the first responder
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    numberTimesViewHasBeenShown++;
}

- (void)viewDidAppear:(BOOL)animated
{
    [[[YouTubeMoviePlayerSingleton createSingleton] youtubePlayer] play];
    [super viewDidAppear:animated];
    if(! self.enoughSongInformationGiven)
        [self setUpAddToLibraryButton];  //only works in viewDidAppear.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    
    //End recieving events
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    
    [[[YouTubeMoviePlayerSingleton createSingleton] youtubePlayer] pause];
    [YouTubeMoviePlayerSingleton setYouTubePlayerInstance:nil];
    numberTimesViewHasBeenShown = 0;
}

#pragma mark - Setting up MPMoviePlayerController
- (void)setUpVideoPlayer
{
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
                    url = [self closestUrlQualityMatchForSetting:maxDesiredQuality usingStreamsDictionary:vidQualityDict];
                    
                }else{
                    short maxDesiredQuality = [AppEnvironmentConstants preferredCellularStreamSetting];
                    url = [self closestUrlQualityMatchForSetting:maxDesiredQuality usingStreamsDictionary:vidQualityDict];
                }
                
                //Now that we have the url, load the video into our MPMoviePlayerController
                [self setUpMPMoviePlayerControllerUsingNSURL:url];
                
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
}

- (NSURL *)closestUrlQualityMatchForSetting:(short)aQualitySetting usingStreamsDictionary:(NSDictionary *)aDictionary
{
    short maxDesiredQuality = aQualitySetting;
    NSDictionary *vidQualityDict = aDictionary;
    NSURL *url;
    switch (maxDesiredQuality) {
        case 240:
        {
            url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualitySmall240]];
            if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityMedium360]];
            else if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityHD720]];
            break;
        }
        case 360:
        {
            url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityMedium360]];
            if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualitySmall240]];
            else if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityHD720]];
            break;
        }
        case 720:
        {
            url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityHD720]];
            if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityMedium360]];
            else if(url == nil)
                url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualitySmall240]];
            break;
        }
        default:
            url = [vidQualityDict objectForKey:[NSNumber numberWithUnsignedInteger:XCDYouTubeVideoQualityMedium360]];
            break;
    }
    return url;
}

- (void)setUpMPMoviePlayerControllerUsingNSURL:(NSURL *)videoUrl
{
    MPMoviePlayerController *videoPlayer = [[MPMoviePlayerController alloc] initWithContentURL:videoUrl];
    [YouTubeMoviePlayerSingleton setYouTubePlayerInstance:videoPlayer];
    videoPlayer.shouldAutoplay = YES;
    
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
    [videoPlayer.view setFrame:CGRectMake(0, 0, headerView.frame.size.width, headerView.frame.size.height)];
    self.tableView.tableHeaderView = headerView;
    
    //present this MPMoviePlayerController inside of the headerView of the table
    videoPlayer.controlStyle = MPMovieControlStyleEmbedded;
	videoPlayer.view.frame = CGRectMake(0.f, 0.f, headerView.bounds.size.width, headerView.bounds.size.height);
	videoPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	if (![headerView.subviews containsObject:videoPlayer.view])
		[headerView addSubview:videoPlayer.view];

    [videoPlayer prepareToPlay];
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
    [imageCache clearDisk];
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

#pragma mark - Control event stuff for video/audio
//Make sure we can recieve remote control events
- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    MPMoviePlayerController *videoPlayer = [[YouTubeMoviePlayerSingleton createSingleton] youtubePlayer];
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlPlay:
                [videoPlayer play];
                break;
            case UIEventSubtypeRemoteControlPause:
                [videoPlayer pause];
                break;
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if (videoPlayer.playbackState == MPMoviePlaybackStatePlaying) {
                    [videoPlayer pause];
                }
                else {
                    [videoPlayer play];
                }
                break;
            default:
                break;
        }
    }
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
    if(_enoughSongInformationGiven){
        //create song and if necessary, the albums artists, etc here.
    }
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
        if(_albumArt){
            _albumArt = [AlbumArtUtilities imageWithImage:_albumArt scaledToSize:CGSizeMake(58, 58)];
            cell.accessoryView = [[UIImageView alloc] initWithImage:_albumArt];
        }
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
            break;
        case 1:
            [txtField setPlaceholder:@"Artist"];
            txtField.tag = Artist_Input_TextField_Tag;
            break;
        case 2:
            [txtField setPlaceholder:@"Album"];
            txtField.tag = Album_Input_TextField_Tag;
            break;
        case 3:
            [txtField setPlaceholder:@"Genre"];
            txtField.tag = Genre_Input_TextField_Tag;
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

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //if(indexPath.section == 3)
        //if(indexPath.row == 0)
            //display album art picker
            
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if(section == 4)
        return @"All fields optional, except 'Song Name'";
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return (section == 4) ? 30.0f : 0.0f;
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
    return (indexPath.row == 3) ? 66.0f : 50.0f;
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
                                            break;
            
        case Artist_Input_TextField_Tag:    break;
        case Album_Input_TextField_Tag:     break;
        case Genre_Input_TextField_Tag:     break;
        default:    break;
    }
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return YES;
}

#pragma mark - Rotation methods
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    UIView *headerView = self.tableView.tableHeaderView;
    CGRect newRect;
    if(toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
        newRect = CGRectMake(0, 0, headerView.frame.size.width, headerView.frame.size.height + Landscape_TableView_Header_Offset);
    else
        newRect = CGRectMake(0, 0, headerView.frame.size.width, headerView.frame.size.height - Landscape_TableView_Header_Offset);
    
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
