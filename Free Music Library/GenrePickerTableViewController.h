//
//  GenrePickerTableViewController.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/14/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDWebImageManager.h"
#import "GenreConstants.h"
#import "GenreSearchService.h"
#import "ArtistTableViewFormatter.h"  //using this since the artist tab also is only text...so its a similar format style

//allows user to pick a genre, and posts the chosen genre via an NSNotification (posting it as an NSString)
@interface GenrePickerTableViewController : UITableViewController <UISearchBarDelegate, GenreSearchDelegate>

- (id)initWithGenreCode:(int)aGenreCode notificationNameToPost:(NSString *)notifName;

@end
