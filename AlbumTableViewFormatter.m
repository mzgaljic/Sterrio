//
//  AlbumTableViewFormatter.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "AlbumTableViewFormatter.h"

@implementation AlbumTableViewFormatter

+ (NSAttributedString *)formatAlbumLabelUsingAlbum:(Album *)anAlbumInstance
{
    if([AppEnvironmentConstants boldNames]){
        switch ([AppEnvironmentConstants preferredSizeSetting])
        {
            case 1:
                return [AlbumTableViewFormatter boldAttributedStringWithString:anAlbumInstance.albumName
                                                                  withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
            case 2:
                return [AlbumTableViewFormatter boldAttributedStringWithString:anAlbumInstance.albumName
                                                                  withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
                
            case 3:  //default app setting when app launched for the first time.
                return [AlbumTableViewFormatter boldAttributedStringWithString:anAlbumInstance.albumName
                                                                  withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
                
            case 4:
                return [AlbumTableViewFormatter boldAttributedStringWithString:anAlbumInstance.albumName
                                                                  withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
                
            case 5:
                return [AlbumTableViewFormatter boldAttributedStringWithString:anAlbumInstance.albumName
                                                                  withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
            case 6:
                return [AlbumTableViewFormatter boldAttributedStringWithString:anAlbumInstance.albumName
                                                                  withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
                
            default:
                return nil;
        }
    } else{
        return [[NSAttributedString alloc] initWithString:anAlbumInstance.albumName];
    }
}

+ (void)formatAlbumDetailLabelUsingAlbum:(Album *)anAlbumInstance andCell:(UITableViewCell **)aCell
{
    [*aCell detailTextLabel].numberOfLines = 0;  //remove line number limit
    //now change the detail label
    [*aCell detailTextLabel].attributedText = [AlbumTableViewFormatter generateDetailLabelAttrStringWithArtistName:anAlbumInstance.artist.artistName
                                                                                                    andSongsCount:(int)anAlbumInstance.albumSongs.count];
}


+ (float)preferredAlbumCellHeight
{
    return [PreferredFontSizeUtility actualCellHeightFromCurrentPreferredSize];
}

+ (CGSize)preferredAlbumAlbumArtSize
{
    return [PreferredFontSizeUtility actualAlbumArtSizeFromCurrentPreferredSize];
}


+ (float)nonBoldAlbumLabelFontSize
{
    return [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
}

+ (BOOL)albumNameIsBold
{
    return [AppEnvironmentConstants boldNames];
}


//private methods
+ (NSAttributedString *)boldAttributedStringWithString:(NSString *)aString withFontSize:(float)fontSize
{
    if(! aString)
        return nil;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:aString];
    [attributedText addAttribute: NSFontAttributeName value:[UIFont boldSystemFontOfSize:fontSize] range:NSMakeRange(0, [aString length])];
    return attributedText;
}

//adds a space to the artist string, then it just changes the album string to grey.
+ (NSAttributedString *)generateDetailLabelAttrStringWithArtistName:(NSString *)artistString andSongsCount:(int)numSongsValue
{
    if(artistString == nil || numSongsValue < 0)
        return nil;
    
    NSString *numSongs = [NSString stringWithFormat:@"%i", numSongsValue];
    NSString *songString;
    if(numSongsValue == 1)
        songString = [NSString stringWithFormat:@"%@ song", numSongs];
    else
        songString = [NSString stringWithFormat:@"%@ songs", numSongs];
    
    const CGFloat fontSize = [PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize];
    UIFont *regularFont = [UIFont systemFontOfSize:fontSize];
    
    //make entire string
    NSMutableString *entireString = [NSMutableString stringWithString:artistString];  //artist name
    [entireString appendString:@"\n"];  //make new line
    [entireString appendString:songString];  //add songs string under artist name
    
    // Create the attributes
    NSDictionary *regAttribute = [NSDictionary dictionaryWithObjectsAndKeys: regularFont, NSFontAttributeName, nil];
    const NSRange range = NSMakeRange(artistString.length +1, songString.length);  //specify range of second line
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:entireString attributes:regAttribute];
    //change font size of the entire second line
    [attributedText addAttribute:NSFontAttributeName
                  value:[UIFont systemFontOfSize:[PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize] - 2]
                  range:range];
    
    return attributedText;
}

@end
