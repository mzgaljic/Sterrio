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
#import "NSString+Levenshtein_Distance.h"
#import "LevenshteinDistanceItem.h"

@implementation CoreDataEntityMappingUtils

+ (Album *)existingAlbumWithName:(NSString *)query
{
#warning should check which thread this work is being performed on (if used in more than 1 place.)
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Album"];
    request.returnsObjectsAsFaults = NO;
    [request setFetchBatchSize:15];
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortAlbumName"
                                                   ascending:YES
                                                    selector:@selector(localizedStandardCompare:)];
    
    request.sortDescriptors = @[sortDescriptor];
    request.predicate = [self generateCompoundPredicateForEntity:[Album alloc] entityName:query];
    NSArray *results = [[CoreDataManager context] executeFetchRequest:request error:nil];
    
    return [self bestResultByApplyingLevenshteinDistanceAlgo:results originalQuery:query];
}

+ (Artist *)existingArtistWithName:(NSString *)query
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
    request.predicate = [self generateCompoundPredicateForEntity:[Artist alloc] entityName:query];
    NSArray *results = [[CoreDataManager context] executeFetchRequest:request error:nil];
    return [self bestResultByApplyingLevenshteinDistanceAlgo:results originalQuery:query];
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

/* Supports results with Album or Artist objects ONLY. */
+ (id)bestResultByApplyingLevenshteinDistanceAlgo:(NSArray *)results originalQuery:(NSString *)query
{
    if(results == nil || results.count == 0) {
        return nil;
    }
    
    //Compute Levenshtein Distance and do a comparison on how 'similar' the result is to the query.
    //it's possible the match from core data could suck. Example: Sugar by Maroon 5. The album
    //name is 'V'. That could return a competely random album from the DB that has a V in it!
    
    NSMutableArray *levenshteinDistances = [NSMutableArray arrayWithCapacity:results.count];
    for(int i = 0; i < results.count; i++) {
        id model = results[i];
        NSString *modelString = nil;
        if([model isMemberOfClass:[Album class]]) {
            modelString = ((Album *)model).albumName;
        } else if([model isMemberOfClass:[Artist class]]) {
            modelString = ((Artist *)model).artistName;
        } else {
            return nil;
        }
        
        NSUInteger distance = [query computeLevenshteinDistanceFromSecondString:modelString];
        LevenshteinDistanceItem *item = [[LevenshteinDistanceItem alloc] init];
        item.distance = distance;
        item.modelObj = model;
        [levenshteinDistances addObject:item];
    }

    //Sort the distances, lowest distance is the best match.
    NSSortDescriptor *lowToHigh = [NSSortDescriptor sortDescriptorWithKey:@"distance" ascending:YES];
    [levenshteinDistances sortUsingDescriptors:@[lowToHigh]];
    
    id bestMatch = nil;
    LevenshteinDistanceItem *item = (LevenshteinDistanceItem *)levenshteinDistances[0];
    //lets consider <= 3 to be a 'good' result.
    if(item.distance <= 3) {
        bestMatch = item.modelObj;
        results = nil;
        levenshteinDistances = nil;
    }

    return bestMatch;
}

@end
