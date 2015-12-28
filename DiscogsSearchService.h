//
//  DiscogsSearchService.h
//  Sterrio
//
//  Created by Mark Zgaljic on 5/15/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DiscogsSearchService : NSObject

- (void)queryWithTitle:(NSString *)title;
- (id)initAndQueryWithTitle:(NSString *)title;

@end
