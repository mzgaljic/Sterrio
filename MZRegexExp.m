//
//  MZRegexExp.m
//  Sterrio
//
//  Created by Mark Zgaljic on 2/6/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZRegexExp.h"

@implementation MZRegexExp

//looks for "ft." and removes everything starting from there to the end of the string.
//pattern: (\(|\[|\{|\s)(ft\..+|feat\..+)
NSString * const MZRegexMatchFeatAndFtToEndOfString = @"(\\(|\\[|\\{|\\s)(ft\\..+|feat\\..+)";

//pattern:  (feat.|ft.)\s*(.+)(&|and)\s*([^\)\]\}\.]+)
//Example: YOLO (ft. Adam Levine & Kendrick Lamar)
//in example, Adam Levine is capture group # 2. Kendrick Lamar is #4.
NSString * const MZRegexMatchFeaturedArtists = @"(feat.|ft.)\\s*(.+)(&|and)\\s*([^\\)\\]\\}\\.]+)";

//pattern: (feat.|ft.)\s*([^\)\]\}\.\&]+)
//Example: YOLO (feat. Adam Levine )
//in example, Adam Levine is capture group #2
NSString * const MZRegexMatchFeaturedArtist = @"(feat\\.|ft\\.)\\s*([^\\)\\]\\}\\.\\&]+)";

@end
