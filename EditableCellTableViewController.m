//
//  EditableCellTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/22/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "EditableCellTableViewController.h"

@interface EditableCellTableViewController ()

@end

@implementation EditableCellTableViewController

//using custom init here
- (id)initWithEditingString:(NSString *)aString
{
    UIStoryboard*  sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EditableCellTableViewController* vc = [sb instantiateViewControllerWithIdentifier:@"editingCellItemView"];
    //self = [super initWithNibName:@"DestinationViewController" bundle:nil];
    self = vc;
    if (self) {
        _stringUserIsEditing = [aString copy];
    }
    return self;
}


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    UITextField * txtField=[[UITextField alloc]initWithFrame:CGRectMake(5, 5, 320, 39)];
    txtField.autoresizingMask=UIViewAutoresizingFlexibleHeight;
    txtField.autoresizesSubviews=YES;
    txtField.layer.cornerRadius=10.0;
    [txtField setBorderStyle:UITextBorderStyleRoundedRect];
    if(_stringUserIsEditing == nil)
        [txtField setPlaceholder:@"Tap me"];
    else{
        txtField.text = [txtField.text stringByAppendingString:_stringUserIsEditing];
    }
    txtField.returnKeyType = UIReturnKeyDone;
    txtField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [txtField becomeFirstResponder];
    [txtField setDelegate:self];
    
    //cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    cell.accessoryType = UITableViewCellAccessoryNone;
    [cell addSubview:txtField];
    
    
    return cell;
}

#pragma mark - UITextField methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"editableCellFinishedEditing" object:textField.text];
    [self.navigationController popViewControllerAnimated:YES];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    NSLog(@"3");
    return YES;
}

@end
