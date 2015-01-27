//
//  ExistingArtistPickerTableViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/14/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "ExistingArtistPickerTableViewController.h"
#import <SDCAlertView.h>
@interface ExistingArtistPickerTableViewController ()
@property(nonatomic, strong) NSMutableArray *allArtists;
@property (nonatomic, strong) Artist *usersCurrentArtist;
@end

@implementation ExistingArtistPickerTableViewController
static BOOL PRODUCTION_MODE;

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:@"Unfinished"
                                                      message:@"This action is not yet supported."
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles: nil];
    alert.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    alert.messageLabelFont = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    alert.suggestedButtonFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    [alert show];
}

- (id)initWithCurrentArtist:(Artist *)anArtist
{
    UIStoryboard*  sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ExistingArtistPickerTableViewController* vc = [sb instantiateViewControllerWithIdentifier:@"browseExistingArtistsVC"];
    self = vc;
    if (self) {
        //custom variables init here
        _usersCurrentArtist = anArtist;
    }
    return self;
}

- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationController.title = @"Existing Artists";
    [self setProductionModeValue];
}

/*
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //init tableView model
    //_allArtists = [NSMutableArray arrayWithArray:[Artist loadAll]];
    [self.tableView reloadData];
}
*/
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.allArtists.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"existingArtistItemPickerCell" forIndexPath:indexPath];
    
    // Configure the cell...
    Artist *artist = [self.allArtists objectAtIndex: indexPath.row];  //get artist object at this index
    
    if([Artist areArtistsEqual:[NSArray arrayWithObjects:artist, _usersCurrentArtist, nil]]){  //disable this cell
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.userInteractionEnabled = NO;
        cell.textLabel.textColor = [UIColor defaultAppColorScheme];
        cell.detailTextLabel.textColor = [UIColor defaultAppColorScheme];
    } else{
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = [UIColor blackColor];
        cell.userInteractionEnabled = YES;
        cell.textLabel.enabled = YES;
        cell.detailTextLabel.enabled = YES;
    }
    
    // init cell fields
    cell.textLabel.attributedText = [ArtistTableViewFormatter formatArtistLabelUsingArtist:artist];
    if(! [ArtistTableViewFormatter artistNameIsBold])
        cell.textLabel.font = [UIFont systemFontOfSize:[ArtistTableViewFormatter nonBoldArtistLabelFontSize]];
    [ArtistTableViewFormatter formatArtistDetailLabelUsingArtist:artist andCell:&cell];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    //could also selectively choose which rows may be deleted here.
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Artist *chosenArtist = self.allArtists[indexPath.row];
    //notifies MasterEditingSongTableViewController.m about the chosen artist.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"existing artist chosen" object:chosenArtist];
    [self.navigationController popViewControllerAnimated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [ArtistTableViewFormatter preferredArtistCellHeight];
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
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        return YES;
    }
    else
        return NO;  //returned when in portrait, or when app is first launching (UIInterfaceOrientationUnknown)
}

@end
