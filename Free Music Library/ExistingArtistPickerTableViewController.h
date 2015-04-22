//
//  ExistingArtistPickerTableViewController.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/14/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataCustomTableViewController.h"
#import "SearchBarDataSourceDelegate.h"
#import "ActionableArtistDataSourceDelegate.h"
#import "ExistingEntityPickerDelegate.h"

@class Artist;
@interface ExistingArtistPickerTableViewController : CoreDataCustomTableViewController
                                                    <SearchBarDataSourceDelegate,
                                                    ActionableArtistDataSourceDelegate>

- (id)initWithCurrentArtist:(Artist *)anArtist
existingEntityPickerDelegate:(id <ExistingEntityPickerDelegate>)delegate;

@end
