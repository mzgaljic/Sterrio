//
//  LicensesViewController.h
//  Sterrio
//
//  Created by Mark Zgaljic on 3/20/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyViewController.h"

@interface LicensesViewController : MyViewController

- (instancetype)initWithLicenses:(NSArray *)arrayOfMZLicenses;
- (void)dismiss;

@end
