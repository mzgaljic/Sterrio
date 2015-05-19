//
//  NSObject+ObjectUUID.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/26/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (ObjectUUID)

/**Generates a Universally Unique Identifier. Typically for object ID's. UUID generation is state-independant.*/
+ (NSString *)UUID;

@end
