//
//  NSObject+Device_Name.h
//  Muzic
//
//  Created by Mark Zgaljic on 8/13/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/utsname.h>

@interface NSObject (Device_Name)

+ (NSString*)deviceName;

@end
