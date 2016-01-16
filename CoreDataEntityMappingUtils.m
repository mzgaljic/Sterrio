//
//  CoreDataEntityMappingUtils.m
//  Sterrio
//
//  Created by Mark Zgaljic on 1/15/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "CoreDataEntityMappingUtils.h"
#import "CoreDataManager.h"
#import "NSString+WhiteSpace_Utility.h"

@implementation CoreDataEntityMappingUtils

+ (Album *)existingAlbumWithName:(NSString *)albumName
{
#warning should check which thread this work is being performed on (if used in more than 1 place.)
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
    request.returnsObjectsAsFaults = NO;
    [request setFetchBatchSize:1];
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortAlbumName"
                                                   ascending:YES
                                                    selector:@selector(localizedStandardCompare:)];
    
    request.sortDescriptors = @[sortDescriptor];
    request.predicate = [self generateCompoundPredicateForEntity:[Album alloc] entityName:albumName];
    NSArray *result = [[CoreDataManager context] executeFetchRequest:request error:nil];
    return (result && result.count > 0) ? result[0] : nil;
}

+ (Artist *)existingArtistWithName:(NSString *)artistName
{
#warning should check which thread this work is being performed on (if used in more than 1 place.)
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Artist"];
    request.returnsObjectsAsFaults = NO;
    [request setFetchBatchSize:1];
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortArtistName"
                                                   ascending:YES
                                                    selector:@selector(localizedStandardCompare:)];
    
    request.sortDescriptors = @[sortDescriptor];
    request.predicate = [self generateCompoundPredicateForEntity:[Artist alloc] entityName:artistName];
    NSArray *result = [[CoreDataManager context] executeFetchRequest:request error:nil];
    return (result && result.count > 0) ? result[0] : nil;
}

+ (NSPredicate *)generateCompoundPredicateForEntity:(id)albumOrArtist entityName:(NSString *)query
{
    NSPredicate *predicate1, *predicate2, *predicate3;
    NSString *sqlLikePattern = [NSString stringWithFormat:@"*%@*", query];
    
    if([albumOrArtist isMemberOfClass:[Album class]]) {
        predicate1 = [NSPredicate predicateWithFormat:@"albumName contains[cd] %@",  query];
        predicate2 = [NSPredicate predicateWithFormat:@"albumName LIKE[cd] %@",  sqlLikePattern];
        NSString *noParensOrBrackets = [self stringWithoutParensOrBrackets:query];
        noParensOrBrackets = [noParensOrBrackets removeIrrelevantWhitespace];
        noParensOrBrackets = [NSString stringWithFormat:@"*%@*", noParensOrBrackets];
        predicate3 = [NSPredicate predicateWithFormat:@"albumName LIKE[cd] %@", noParensOrBrackets];
        return [NSCompoundPredicate orPredicateWithSubpredicates:@[predicate1, predicate2, predicate3]];
        
    } else if([albumOrArtist isMemberOfClass:[Artist class]]) {
        predicate1 = [NSPredicate predicateWithFormat:@"artistName contains[cd] %@",  query];
        predicate2 = [NSPredicate predicateWithFormat:@"artistName LIKE[cd] %@",  sqlLikePattern];
        return [NSCompoundPredicate orPredicateWithSubpredicates:@[predicate1, predicate2]];
        
    } else {
        return nil;
    }
}

+ (NSString *)stringWithoutParensOrBrackets:(NSString *)originalString
{
    NSMutableString *newString = [NSMutableString stringWithString:[originalString copy]];
    NSString *regexText = @"(\\(.*\\))|(\\[.*\\])";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexText
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    [regex replaceMatchesInString:newString
                          options:0
                            range:NSMakeRange(0, [newString length])
                     withTemplate:@""];
    return newString;
}

@end
