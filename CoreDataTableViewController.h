//
//  CoreDataTableViewController.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/16/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "CoreDataManager.h"
#import "UIColor+LighterAndDarker.h"
#import "MySearchBar.h"

@interface CoreDataTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>

//The controller (this class fetches nothing if it is not set).
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSFetchedResultsController *searchFetchedResultsController;
@property (nonatomic) BOOL displaySearchResults;

// Causes the fetchedResultsController to refresh the data.
// You almost certainly never need to call this.
// The NSFetchedResultsController class observes the context,
// so if the objects in the context change, you do not need to call performFetch
// since the NSFetchedResultsController will notice and update the table automatically.

//This will also automatically be called if you change the fetchedResultsController @property.
- (void)performFetch;

@end
