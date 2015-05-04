//
//  StreamQualityPickerTableViewController.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/29/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MyTableViewController.h"

typedef enum{
    VIDEO_QUALITY_STREAM_TYPE_Wifi,
    VIDEO_QUALITY_STREAM_TYPE_Cellular
} VIDEO_QUALITY_STREAM_TYPE;

@interface StreamQualityPickerTableViewController : MyTableViewController
@property (nonatomic, assign) VIDEO_QUALITY_STREAM_TYPE streamType;
@property (nonatomic, assign) int defaultStreamSetting;
@property (nonatomic, strong) NSArray *streamQualityOptions;
@end
