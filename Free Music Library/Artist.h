//
//  Artist.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 6/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Artist : NSObject <NSCoding>

@property(atomic, strong) NSString *artistName;

@end
