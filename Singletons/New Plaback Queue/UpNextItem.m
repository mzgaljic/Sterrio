//
//  UpNextItem.m
//  Sterrio
//
//  Created by Mark Zgaljic on 8/28/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "UpNextItem.h"

@implementation UpNextItem

- (id)initWithContext:(PlaybackContext *)context enumerator:(MZEnumerator *)enumerator
{
    if(self = [super init]) {
        _context = context;
        _enumeratorForContext = enumerator;
    }
    return self;
}

@end
