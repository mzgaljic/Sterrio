//
//  ExistingAlbumPickerTableViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/14/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "ExistingAlbumPickerTableViewController.h"
#import <SDCAlertView.h>

@interface ExistingAlbumPickerTableViewController ()
@property (nonatomic, strong) NSMutableArray *albums;
@property (nonatomic, strong) Album *usersCurrentAlbum;
@end

@implementation ExistingAlbumPickerTableViewController
@synthesize albums;
/*
//using custom init here
- (id)initWithCurrentAlbum:(Album *)anAlbum
{
    UIStoryboard*  sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ExistingAlbumPickerTableViewController* vc = [sb instantiateViewControllerWithIdentifier:@"browseExistingAlbumsVC"];
    self = vc;
    if (self) {
        //custom variables init here
        _usersCurrentAlbum = anAlbum;
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
    
    self.navigationController.navigationController.title = @"Existing Albums";
    [self setProductionModeValue];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //init tableView model
    self.albums = [NSMutableArray arrayWithArray:[Album loadAll]];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"existingAlbumCell" forIndexPath:indexPath];
    // Configure the cell...
    
    Album *album = [self.albums objectAtIndex: indexPath.row];  //get album instance at this index
    if([album isEqual:_usersCurrentAlbum]){  //disable this cell
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.userInteractionEnabled = NO;
        cell.textLabel.textColor = [UIColor defaultSystemTintColor];
        cell.detailTextLabel.textColor = [UIColor defaultSystemTintColor];
    }
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
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [AlbumTableViewFormatter preferredAlbumCellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Album *chosenAlbum = self.albums[indexPath.row];
    //notifies MasterEditingSongTableViewController.m about the chosen album.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"existing album chosen" object:chosenAlbum];
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSAttributedString *)BoldAttributedStringWithString:(NSString *)aString withFontSize:(float)fontSize
{
    if(! aString)
        return nil;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:aString];
    [attributedText addAttribute: NSFontAttributeName value:[UIFont boldSystemFontOfSize:fontSize] range:NSMakeRange(0, [aString length])];
    return attributedText;
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
*/

@end
