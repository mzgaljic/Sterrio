//
//  ExistingAlbumPickerTableViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 8/14/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "ExistingAlbumPickerTableViewController.h"

@interface ExistingAlbumPickerTableViewController ()
@property (nonatomic, strong) NSMutableArray *albums;
@property (nonatomic, strong) Album *usersCurrentAlbum;
@end

@implementation ExistingAlbumPickerTableViewController
@synthesize albums;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationController.title = @"All Albums";
}



#pragma mark - Table view data source
/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Album *chosenAlbum = self.albums[indexPath.row];
    //notifies MasterEditingSongTableViewController.m about the chosen album.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"existing album chosen" object:chosenAlbum];
    [self.navigationController popViewControllerAnimated:YES];
}
*/

- (BOOL)prefersStatusBarHidden
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        return YES;
    }
    else
        return NO;
}

@end
