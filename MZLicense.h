//
//  MZLicense.h
//  Sterrio
//
//  Created by Mark Zgaljic on 3/20/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MZLicense : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *body;

+ (NSArray *)allProjectLicenses;

@end
