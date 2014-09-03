//
//  ExistingArtistPickerTableViewController.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/14/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppEnvironmentConstants.h"
#import "Album.h"
#import "Artist+Utilities.h"
#import "ArtistTableViewFormatter.h"
#import "SDWebImageManager.h"
#import "UIColor+SystemTintColor.h"

@interface ExistingArtistPickerTableViewController : UITableViewController

- (id)initWithCurrentArtist:(Artist *)anArtist;

@end
