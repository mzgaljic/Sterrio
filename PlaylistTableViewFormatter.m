//
//  PlaylistTableViewFormatter.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/22/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PlaylistTableViewFormatter.h"

@implementation PlaylistTableViewFormatter

+ (NSAttributedString *)formatPlaylistLabelUsingPlaylist:(Playlist *)aPlaylistInstance
{
    float size = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize] + 0.0;
    if([AppEnvironmentConstants boldNames]){
        switch ([AppEnvironmentConstants preferredSizeSetting])
        {
            case 1:
                return [PlaylistTableViewFormatter boldAttributedStringWithString:aPlaylistInstance.playlistName withFontSize:size];
            case 2:
                return [PlaylistTableViewFormatter boldAttributedStringWithString:aPlaylistInstance.playlistName withFontSize:size];
                
            case 3:  //default app setting when app launched for the first time.
                return [PlaylistTableViewFormatter boldAttributedStringWithString:aPlaylistInstance.playlistName withFontSize:size];
                
            case 4:
                return [PlaylistTableViewFormatter boldAttributedStringWithString:aPlaylistInstance.playlistName withFontSize:size];
                
            case 5:
                return [PlaylistTableViewFormatter boldAttributedStringWithString:aPlaylistInstance.playlistName withFontSize:size];
            case 6:
                return [PlaylistTableViewFormatter boldAttributedStringWithString:aPlaylistInstance.playlistName withFontSize:size];
            default:
                return nil;
        }
    } else{
        return [[NSAttributedString alloc] initWithString:aPlaylistInstance.playlistName];
    }
}


+ (float)preferredPlaylistCellHeight
{
    //customized cell heights for playlist
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


+ (float)nonBoldPlaylistLabelFontSize
{
    return [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
}

+ (BOOL)playlistNameIsBold
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
