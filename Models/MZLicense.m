//
//  MZLicense.m
//  Sterrio
//
//  Created by Mark Zgaljic on 3/20/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZLicense.h"

@implementation MZLicense

+ (NSArray *)allProjectLicenses
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Licenses" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    NSArray *prefSpecifiers = [dict valueForKey:@"PreferenceSpecifiers"];
    NSMutableArray *mzLicenses = [NSMutableArray arrayWithCapacity:prefSpecifiers.count];
    
    for(NSDictionary *prefSpecifier in prefSpecifiers) {
        MZLicense *license = [MZLicense new];
        license.title = [prefSpecifier valueForKey:@"Title"];
        license.body = [prefSpecifier valueForKey:@"FooterText"];
        [mzLicenses addObject:license];
    }
    return mzLicenses;
}

@end
