//
//  ExistingAlbumPickerTableViewController.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/14/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataCustomTableViewController.h"
#import "SearchBarDataSourceDelegate.h"
#import "ActionableAlbumDataSourceDelegate.h"
#import "ExistingEntityPickerDelegate.h"

@class Album;
@interface ExistingAlbumPickerTableViewController : CoreDataCustomTableViewController
                                                            <SearchBarDataSourceDelegate,
                                                            ActionableAlbumDataSourceDelegate>

- (id)initWithCurrentAlbum:(Album *)anAlbum
existingEntityPickerDelegate:(id <ExistingEntityPickerDelegate>)delegate;


@end
