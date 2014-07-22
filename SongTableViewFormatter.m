//
//  SongTableViewFormatter.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/18/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "SongTableViewFormatter.h"

@implementation SongTableViewFormatter

+ (NSAttributedString *)formatSongLabelUsingSong:(Song *)aSongInstance
{
    if([AppEnvironmentConstants boldNames]){
        switch ([AppEnvironmentConstants preferredSizeSetting])
        {
            case 1:
                return [SongTableViewFormatter boldAttributedStringWithString:aSongInstance.songName
                                                                 withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
            case 2:
                return [SongTableViewFormatter boldAttributedStringWithString:aSongInstance.songName
                                                                 withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
                
            case 3:  //default app setting when app launched for the first time.
                return [SongTableViewFormatter boldAttributedStringWithString:aSongInstance.songName
                                                                 withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
                
            case 4:
                return [SongTableViewFormatter boldAttributedStringWithString:aSongInstance.songName
                                                                 withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
                
            case 5:
                return [SongTableViewFormatter boldAttributedStringWithString:aSongInstance.songName
                                                                 withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
            case 6:
                return [SongTableViewFormatter boldAttributedStringWithString:aSongInstance.songName
                                                                 withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
            default:
                return nil;
        }
    } else{
        return [[NSAttributedString alloc] initWithString:aSongInstance.songName];  //in this case, the caller must set the size themselves
    }
}

+ (BOOL)songNameIsBold
{
    return [AppEnvironmentConstants boldNames];
}

+ (void)formatSongDetailLabelUsingSong:(Song *)aSongInstance andCell:(UITableViewCell **)aCell
{
    //now change the detail label
    [*aCell detailTextLabel].attributedText = [SongTableViewFormatter generateDetailLabelAttrStringWithArtistName:aSongInstance.artist.artistName
                                                                                                     andAlbumName:aSongInstance.album.albumName];
    [*aCell detailTextLabel].font = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize]];
}

//used when formatting for non-bold names
+ (float)nonBoldSongLabelFontSize
{
    return [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
}

+ (float)preferredSongCellHeight
{
    //customized cell heights for songs (very similar to albums...only case 6 differs)
    switch ([AppEnvironmentConstants preferredSizeSetting])
    {
        case 2:
            return [PreferredFontSizeUtility actualCellHeightFromCurrentPreferredSize] + 3.0;
            
            //make rows smaller when the font is this huge (5 & 6), to fit as much content as possible
        case 5:
            return [PreferredFontSizeUtility actualCellHeightFromCurrentPreferredSize] - 15.0;
        case 6:
            return [PreferredFontSizeUtility actualCellHeightFromCurrentPreferredSize] - 35.0;
            
        default:
            return [PreferredFontSizeUtility actualCellHeightFromCurrentPreferredSize];
    }
}

+ (CGSize)preferredSongAlbumArtSize
{
    return [PreferredFontSizeUtility actualAlbumArtSizeFromCurrentPreferredSize];
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
+ (NSAttributedString *)generateDetailLabelAttrStringWithArtistName:(NSString *)artistString andAlbumName:(NSString *)albumString
{
    if(artistString == nil || albumString == nil)
        return nil;
    NSMutableString *newArtistString = [NSMutableString stringWithString:artistString];
    [newArtistString appendString:@" "];
    
    NSMutableString *entireString = [NSMutableString stringWithString:newArtistString];
    [entireString appendString:albumString];
    
    NSArray *components = @[newArtistString, albumString];
    //NSRange untouchedRange = [entireString rangeOfString:[components objectAtIndex:0]];
    NSRange grayRange = [entireString rangeOfString:[components objectAtIndex:1]];
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:entireString];
    
    [attrString beginEditing];
    [attrString addAttribute: NSForegroundColorAttributeName
                       value:[UIColor grayColor]
                       range:grayRange];
    [attrString endEditing];
    return attrString;
}

@end
