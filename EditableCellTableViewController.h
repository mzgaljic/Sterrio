//
//  EditableCellTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/22/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDWebImageManager.h"
#import "MyTableViewController.h"

@interface EditableCellTableViewController : MyTableViewController <UITextFieldDelegate>

@property (nonatomic, strong) NSString *stringUserIsEditing;

- (id)initWithEditingString:(NSString *)aString notificationNameToPost:(NSString *)notifName;

@end
