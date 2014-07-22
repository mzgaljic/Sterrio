//
//  ArtistTableViewFormatter.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "ArtistTableViewFormatter.h"

@implementation ArtistTableViewFormatter

+ (NSAttributedString *)formatArtistLabelUsingArtist:(Artist *)anArtistInstance
{
    if([AppEnvironmentConstants boldNames]){
        switch ([AppEnvironmentConstants preferredSizeSetting])
        {
            case 1:
                return [ArtistTableViewFormatter boldAttributedStringWithString:anArtistInstance.artistName
                                                                  withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
            case 2:
                return [ArtistTableViewFormatter boldAttributedStringWithString:anArtistInstance.artistName
                                                                  withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
                
            case 3:  //default app setting when app launched for the first time.
                return [ArtistTableViewFormatter boldAttributedStringWithString:anArtistInstance.artistName
                                                                  withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
                
            case 4:
                return [ArtistTableViewFormatter boldAttributedStringWithString:anArtistInstance.artistName
                                                                  withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
                
            case 5:
                return [ArtistTableViewFormatter boldAttributedStringWithString:anArtistInstance.artistName
                                                                  withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
            case 6:
                return [ArtistTableViewFormatter boldAttributedStringWithString:anArtistInstance.artistName
                                                                  withFontSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
                
            default:
                return nil;
        }
    } else{
        return [[NSAttributedString alloc] initWithString:anArtistInstance.artistName];
    }
}

+ (void)formatArtistDetailLabelUsingArtist:(Artist *)anArtistInstance andCell:(UITableViewCell **)aCell
{
    Artist *artist = anArtistInstance;
    int songsInAlbumsCount = 0;
    //count all the songs that are associated with albums for this artist
    for(int i = 0; i < artist.allAlbums.count; i++){
        Album *anAlbum = artist.allAlbums[i];
        for(int k = 0; k < anAlbum.albumSongs.count; k++){
            songsInAlbumsCount++;
        }
    }
    
    NSString *albumPart, *songPart;
    if((int)artist.allAlbums.count == 1)
        albumPart = @"1 Album";
    else
        albumPart = [NSString stringWithFormat:@"%d Albums", (int)artist.allAlbums.count];
    
    if((int)artist.allSongs.count + songsInAlbumsCount == 1)
        songPart = @"1 Song";
    else
        songPart = [NSString stringWithFormat:@"%d Songs", (int)artist.allSongs.count + songsInAlbumsCount];
    
    NSMutableString *finalDetailLabel = [NSMutableString stringWithString:albumPart];
    [finalDetailLabel appendString:@" "];
    [finalDetailLabel appendString:songPart];
    
    //now change the detail label
    [*aCell detailTextLabel].text = finalDetailLabel;
    [*aCell detailTextLabel].font = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize]];
}


+ (float)preferredArtistCellHeight
{
    return [PreferredFontSizeUtility actualCellHeightFromCurrentPreferredSize];
}


+ (float)nonBoldArtistLabelFontSize
{
    return [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
}

+ (BOOL)artistNameIsBold
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


@end
