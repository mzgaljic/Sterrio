//
//  MasterSongEditorViewController.m
//  Muzic
//
//  Created by Mark Zgaljic on 1/25/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MasterSongEditorViewController.h"

@interface MasterSongEditorViewController ()
{
    BOOL dontPreDealloc;
}
@property (nonatomic, strong) MZSongModifierTableView *tableView;
@end

@implementation MasterSongEditorViewController

#pragma mark - VC lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    MZSongModifierTableView *songEditTable;
    songEditTable = [[MZSongModifierTableView alloc] initWithFrame:self.view.frame
                                                             style:UITableViewStyleGrouped];
    songEditTable.songIAmEditing = self.songIAmEditing;
    songEditTable.VC = self;
    self.tableView = songEditTable;
    self.tableView.theDelegate = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight |
    UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.tableView];
    [self.tableView initWasCalled];
    [self setUpNavBarButtons];
}

static int timesVCHasAppeared = 0;
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView viewWillAppear:animated];
    dontPreDealloc = NO;
    
    //set nav bar title (0 is the index since this is the first VC on the stack)
    UINavigationController *navCon  = (UINavigationController*) [self.navigationController.viewControllers objectAtIndex:0];
    navCon.navigationItem.title = @"Song Edit";
    
    short navBarHeight = 44;
    short padding;
    if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)
        padding = 50;
    else
        padding = 24;
    
    //makes the tableview start below the nav bar
    if(timesVCHasAppeared == 0 || dontPreDealloc){
        UIEdgeInsets inset = UIEdgeInsetsMake(navBarHeight + padding, 0, 0, 0);
        self.tableView.contentInset = inset;
        self.tableView.scrollIndicatorInsets = inset;
    }
    timesVCHasAppeared++;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    BOOL newVcHasBeenPushed = ![self isMovingFromParentViewController];
    if(newVcHasBeenPushed)
        return;
    else
        if(! dontPreDealloc)
            [self preDealloc];
}

- (void)preDealloc
{
    timesVCHasAppeared = 0;
    if(dontPreDealloc)
        return;
    //VC is actually being popped.
    [self.tableView preDealloc];
    self.tableView = nil;
}

#pragma mark - Nav bar code
- (void)setUpNavBarButtons
{
    UIBarButtonItem *cancel, *save;
    cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                           target:self
                                                           action:@selector(cancelTapped)];
    save = [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(saveTapped)];
    self.navigationItem.leftBarButtonItem = cancel;
    self.navigationItem.rightBarButtonItem = save;
}

- (void)saveTapped
{
    timesVCHasAppeared = 0;
    [self.tableView songEditingWasSuccessful];
}

- (void)cancelTapped
{
    timesVCHasAppeared = 0;
    [self.tableView cancelEditing];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.tableView interfaceIsAboutToRotate];
}

#pragma mark - Custom song tableview editor delegate stuff
- (void)pushThisVC:(UIViewController *)vc
{
    //using isKindOfClass because im not looking for an exact match! Just looking for
    //any descendant of these types.
    if([vc isKindOfClass:[UINavigationController class]])
        [self presentViewController:vc animated:YES completion:nil];
    else if([vc isKindOfClass:[UIViewController class]])
        [self.navigationController pushViewController:vc animated:YES];
}

- (void)performCleanupBeforeSongIsSaved:(Song *)newLibSong
{
    [self performSelector:@selector(destructThisVCDelayed) withObject:nil afterDelay:0.2];
}

- (void)destructThisVCDelayed
{
    [self preDealloc];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)songSaveInitiated
{
    //no implementation necessary at this time.
}

@end
