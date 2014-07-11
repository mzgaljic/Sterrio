//
//  BackupFileHelper.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/11/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "BackupFileHelper.h"

@implementation BackupFileHelper

+ (NSString *)newBackupStringForBackupString:(NSString *)aString
{
    if([aString isEqualToString:@"[0]"])  //increment 0 to 1
        return @"[1]";
    else if([aString isEqualToString:@"[1]"])
        return @"[2]";
    else if([aString isEqualToString:@"[2]"])
        return @"[3]";
    else if([aString isEqualToString:@"[3]"])
        return @"[4]";
    else if([aString isEqualToString:@"[4]"])
        return @"[5]";
    else
        return nil;  //should have no more than 5 backups!
}

@end
