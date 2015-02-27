//
//  EditableCellTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/22/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "EditableCellTableViewController.h"


@interface EditableCellTableViewController ()
{
    BOOL fullScreen;
}
@property (nonatomic, strong) NSString *notificationName;
@end

@implementation EditableCellTableViewController

//using custom init here
- (id)initWithEditingString:(NSString *)aString
     notificationNameToPost:(NSString *)notifName
                 fullScreen:(BOOL)full
{
    UIStoryboard*  sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EditableCellTableViewController* vc = [sb instantiateViewControllerWithIdentifier:@"editingCellItemView"];
    self = vc;
    if (self) {
        if(_stringUserIsEditing == nil)
            _stringUserIsEditing = @"";
        _stringUserIsEditing = [aString copy];
        _notificationName = notifName;
        fullScreen = full;
    }
    return self;
}

- (void)viewDidLoad
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
        [self setLandscapeTableViewContentValues];
    else
        [self setPortraitTableViewContentValues];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"editMeCell" forIndexPath:indexPath];
    
    // Configure the cell...
    UITextField * txtField = [[UITextField alloc]initWithFrame:CGRectMake(0,
                                                                          0,
                                                                          cell.frame.size.width,
                                                                          cell.frame.size.height)];
    txtField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    txtField.autoresizesSubviews = YES;
    txtField.layer.cornerRadius = 10.0;
    [txtField setBorderStyle:UITextBorderStyleRoundedRect];
    txtField.tintColor = [[UIColor defaultAppColorScheme] lighterColor];
    if(_stringUserIsEditing == nil)
        [txtField setPlaceholder:@"Start Typing"];
    else{
        txtField.text = [txtField.text stringByAppendingString:_stringUserIsEditing];
    }
    txtField.font = [UIFont systemFontOfSize:20.0];
    txtField.returnKeyType = UIReturnKeyDone;
    txtField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [txtField becomeFirstResponder];
    [txtField setDelegate:self];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    [cell addSubview:txtField];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

#pragma mark - UITextField methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [[NSNotificationCenter defaultCenter] postNotificationName:_notificationName
                                                        object:textField.text];
    [self.navigationController popViewControllerAnimated:YES];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return YES;
}


#pragma mark - Rotation code
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self prefersStatusBarHidden];
    [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (BOOL)prefersStatusBarHidden
{
    if(fullScreen)
        return YES;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        [self setLandscapeTableViewContentValues];
        return YES;
    }
    else{
        [self setPortraitTableViewContentValues];
        return NO;
    }
}

- (void)setLandscapeTableViewContentValues
{
    //remove header gap at top of table
    [self.tableView setContentInset:UIEdgeInsetsMake(0,0,0,0)];
    [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(0,0,0,0)];
}
- (void)setPortraitTableViewContentValues
{
    //remove header gap at top of table
    [self.tableView setContentInset:UIEdgeInsetsMake(68,0,-68,0)];
    [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(68,0,-68,0)];
}


@end
