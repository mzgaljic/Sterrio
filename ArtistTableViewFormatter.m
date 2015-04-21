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
    float size = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize] + 1.0;
    if([AppEnvironmentConstants boldNames]){
        switch ([AppEnvironmentConstants preferredSizeSetting])
        {
            case 1:
                return [ArtistTableViewFormatter boldAttributedStringWithString:anArtistInstance.artistName withFontSize:size];
            case 2:
                return [ArtistTableViewFormatter boldAttributedStringWithString:anArtistInstance.artistName withFontSize:size];
                
            case 3:  //default app setting when app launched for the first time.
                return [ArtistTableViewFormatter boldAttributedStringWithString:anArtistInstance.artistName withFontSize:size];
                
            case 4:
                return [ArtistTableViewFormatter boldAttributedStringWithString:anArtistInstance.artistName withFontSize:size];
                
            case 5:
                return [ArtistTableViewFormatter boldAttributedStringWithString:anArtistInstance.artistName withFontSize:size];
            case 6:
                return [ArtistTableViewFormatter boldAttributedStringWithString:anArtistInstance.artistName withFontSize:size];
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
    //count all the songs that are associated with albums for this artist
    NSMutableSet *allAlbumSongsFromArtist = [[NSMutableSet alloc] initWithCapacity:6];
    for(Album *artistAlbum in artist.albums)
    {
        NSSet *albumSongs = artistAlbum.albumSongs;
        NSSet *tempNewSet = [allAlbumSongsFromArtist setByAddingObjectsFromSet:albumSongs];
        allAlbumSongsFromArtist = [NSMutableSet setWithSet:tempNewSet];
    }
    NSSet *albumSongs = artist.standAloneSongs;
    NSSet *uniqueSongsByThisArtist = [allAlbumSongsFromArtist setByAddingObjectsFromSet:albumSongs];
    
    NSString *albumPart, *songPart;
    if((int)artist.albums.count == 1)
        albumPart = @"1 Album";
    else
        albumPart = [NSString stringWithFormat:@"%d Albums", (int)artist.albums.count];
    
    NSUInteger totalSongCount = uniqueSongsByThisArtist.count;
    if(totalSongCount == 1)
        songPart = @"1 Song ";
    else
        songPart = [NSString stringWithFormat:@"%d Songs", (int)totalSongCount];
    
    NSMutableString *finalDetailLabel = [NSMutableString stringWithString:albumPart];
    [finalDetailLabel appendString:@" "];
    [finalDetailLabel appendString:songPart];
    
    //now change the detail label
    [*aCell detailTextLabel].text = finalDetailLabel;
    [*aCell detailTextLabel].font = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualDetailLabelFontSizeFromCurrentPreferredSize] -2.0];
}


+ (float)preferredArtistCellHeight
{
    //customized cell heights for artists
    switch ([AppEnvironmentConstants preferredSizeSetting])
    {
        case 1:
            return [PreferredFontSizeUtility actualCellHeightFromCurrentPreferredSize] - 3.0;
        case 2:
            return [PreferredFontSizeUtility actualCellHeightFromCurrentPreferredSize] - 5.0;
        case 3:
            return [PreferredFontSizeUtility actualCellHeightFromCurrentPreferredSize] - 16.0;
        case 4:
            return [PreferredFontSizeUtility actualCellHeightFromCurrentPreferredSize] - 25.0;
        case 5:
            return [PreferredFontSizeUtility actualCellHeightFromCurrentPreferredSize] - 26.0;
        case 6:
            return [PreferredFontSizeUtility actualCellHeightFromCurrentPreferredSize] - 45.0;
            
        default:
            return [PreferredFontSizeUtility actualCellHeightFromCurrentPreferredSize];
    }
}


+ (float)nonBoldArtistLabelFontSize
{
    return [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize] + 1.0;
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
