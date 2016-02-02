//
//  MZRightDetailCell.h
//  Sterrio
//
//  Created by Mark Zgaljic on 2/1/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MGSwipeTableCell.h"

/* Ensures that the detailTextLabel (the one on the right in gray text normally) is never
 cut off by the textLabel. On a regular UITableViewCell with the RightDetail style, the
 textLabel can completely push the detailTextLabel off of the contentView.
 */
@interface MZRightDetailCell : MGSwipeTableCell

@end
