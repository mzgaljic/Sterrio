//
//  UpNextItem.h
//  Sterrio
//
//  Created by Mark Zgaljic on 8/28/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MZEnumerator.h"
#import "PlaybackContext.h"

@interface UpNextItem : NSObject
@property (nonatomic, strong, readonly) PlaybackContext *context;
@property (nonatomic, strong, readonly) MZEnumerator *enumeratorForContext;

- (id)initWithContext:(PlaybackContext *)context enumerator:(MZEnumerator *)enumerator;

@end
