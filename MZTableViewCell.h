//
//  MZTableViewCell.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 2/6/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

//This is a regular UITableViewCell with an override method
//to force the imageview to be all the way to the left side.
#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"

@interface MZTableViewCell : MGSwipeTableCell

@property (nonatomic, strong) NSManagedObjectID *anAlbumArtClassObjId;
@property (nonatomic, assign) BOOL optOutOfImageView;
@property (nonatomic, assign) BOOL displayQueueSongsMode;
@property (nonatomic, assign) BOOL isRepresentingAQueuedSong;

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier;

+ (float)percentTextLabelIsDecreasedFromTotalCellHeight;

@end
