//
//  SongCreationTableViewController.m
//  zTunes
//
//  Created by Mark Zgaljic on 8/4/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "SongCreationTableViewController.h"

@interface SongCreationTableViewController ()
@property (nonatomic, strong) UIBarButtonItem *backButton;
@property (nonatomic, strong) UIBarButtonItem *nextOrFinishButton;

@property (nonatomic, strong) NSString *textInField;
@end

@implementation SongCreationTableViewController
@synthesize selectedVideo = _selectedVideo;
static BOOL PRODUCTION_MODE;

- (void)setProductionModeValue
{
    PRODUCTION_MODE = [AppEnvironmentConstants isAppInProductionMode];
}

#pragma mark - Custom initializer
- (id) initWithYouTubeVideo:(YouTubeVideo *)aYouTubeVideoObject
{
    UIStoryboard*  sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SongCreationTableViewController* vc = [sb instantiateViewControllerWithIdentifier:@"songCellItemView"];
    self = vc;
    if (self) {
        _selectedVideo = aYouTubeVideoObject;
    }

    return self;
}

#pragma mark - Toolbar methods
- (void)backButtonTapped
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)nextButtonTapped
{
    
}

- (void)setUpBackButton
{
    //code from http://stackoverflow.com/questions/227078/creating-a-left-arrow-button-like-uinavigationbars-back-style-on-a-uitoolba
    UIColor *appTint = [[[UIApplication sharedApplication] delegate] window].tintColor;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[self BackButtonWithColor:appTint]];
    [imageView setTintColor:appTint];
    [imageView setUserInteractionEnabled:YES];
    UILabel *label = [[UILabel alloc] init];
    [label setTextColor:appTint];
    [label setText:@"Search Results"];
    [label sizeToFit];
    
    int space = 6;
    label.frame = CGRectMake(imageView.frame.origin.x+imageView.frame.size.width+space, label.frame.origin.y, label.frame.size.width, label.frame.size.height);
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, label.frame.size.width+imageView.frame.size.width+space, imageView.frame.size.height)];
    [view setUserInteractionEnabled:YES];
    
    view.bounds = CGRectMake(view.bounds.origin.x+8, view.bounds.origin.y-1, view.bounds.size.width, view.bounds.size.height);
    [view addSubview:imageView];
    [view addSubview:label];
    
    UIButton *button = [[UIButton alloc] initWithFrame:view.frame];
    [button setUserInteractionEnabled:YES];
    [button addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:button];
    
    [UIView animateWithDuration:0.33 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        label.alpha = 0.0;
        CGRect orig = label.frame;
        label.frame = CGRectMake(label.frame.origin.x+25, label.frame.origin.y, label.frame.size.width, label.frame.size.height);
        label.alpha = 1.0;
        label.frame = orig;
    } completion:nil];
    
    _backButton =[[UIBarButtonItem alloc] initWithCustomView:view];
    [button addTarget:self action:@selector(backButtonIsBeingTouched) forControlEvents:UIControlEventTouchDown];
}

- (void)backButtonIsBeingTouched
{
    
}

- (UIImage *)BackButtonWithColor:(UIColor *)aColor
{
    UIImage *img = [UIImage imageNamed:@"back button chevron"];
    return [img colorImageWithColor:aColor];
}


#pragma mark - View Controller lifecycle methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self setProductionModeValue];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setUpBackButton];
    
    [self setToolbarItems:@[_backButton]];
    
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.toolbarHidden = NO;
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
        [self setLandscapeTableViewContentValues];
    else
        [self setPortraitTableViewContentValues];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
    [imageCache clearDisk];
}

#pragma mark - TableView deleagte
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

/**
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{

}
 */

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"songCreationFieldCell" forIndexPath:indexPath];
    
    // Configure the cell...
    UITextField * txtField = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height)];
    txtField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    txtField.autoresizesSubviews = YES;
    txtField.layer.cornerRadius = 10.0;
    [txtField setBorderStyle:UITextBorderStyleRoundedRect];
    [txtField setPlaceholder:@"Song name here"];
    txtField.font = [UIFont systemFontOfSize:20.0];
    txtField.returnKeyType = UIReturnKeyDone;
    txtField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [txtField becomeFirstResponder];
    [txtField setDelegate:self];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    [cell addSubview:txtField];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    //could also selectively choose which rows may be deleted here.
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

#pragma mark - UITextField methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    //[self.navigationController popViewControllerAnimated:YES];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return YES;
}

//called whenever text is entered into the textfield
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if(string.length == 0 && range.location == 0 && range.length == 1)  //going to have an empty textField
        textField.returnKeyType = UIReturnKeyDone;
    else
        textField.returnKeyType = UIReturnKeyNext;
    [textField reloadInputViews];
    return YES;
}

#pragma mark - Rotation code
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
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        [self setLandscapeTableViewContentValues];
        return YES;
    }
    else{
        [self setPortraitTableViewContentValues];
        return NO;  //returned when in portrait, or when app is first launching (UIInterfaceOrientationUnknown)
    }
}

- (void)setLandscapeTableViewContentValues
{
    //remove header gap at top of table, and remove some scrolling space under the delete button (update scroll insets too)
    [self.tableView setContentInset:UIEdgeInsetsMake(43,0,-43,0)];
    [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(43,0,-43,0)];
    
    //[self.tableView reloadData];
}
- (void)setPortraitTableViewContentValues
{
    //remove header gap at top of table, and remove some scrolling space under the delete button (update scroll insets too)
    [self.tableView setContentInset:UIEdgeInsetsMake(122,0,-122,0)];
    [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(122,0,-122,0)];
}


@end
