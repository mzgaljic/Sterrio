//
//  SongTableViewFormatter.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/18/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "SongTableViewFormatter.h"

//[UIFont systemFontOfSize:19.0];
//[self generateDetailLabelAttrStringWithArtistName:song.artist.artistName andAlbumName:song.album.albumName];
@implementation SongTableViewFormatter
static const bool SONG_NAME_SHOULD_BE_BOLD = YES;

+ (NSAttributedString *)formatSongLabelUsingSong:(Song *)aSongInstance
{
    short size = [AppEnvironmentConstants preferredSizeSetting];
    
    if(SONG_NAME_SHOULD_BE_BOLD){
        switch (size)
        {
            case 1:
                return [SongTableViewFormatter boldAttributedStringWithString:aSongInstance.songName withFontSize:14.0];
            case 2:
                return [SongTableViewFormatter boldAttributedStringWithString:aSongInstance.songName withFontSize:15.0];
                
            case 3:  //default app setting when app launched for the first time.
                return [SongTableViewFormatter boldAttributedStringWithString:aSongInstance.songName withFontSize:16.0];
                
            case 4:
                return [SongTableViewFormatter boldAttributedStringWithString:aSongInstance.songName withFontSize:19.0];
                
            case 5:
                return [SongTableViewFormatter boldAttributedStringWithString:aSongInstance.songName withFontSize:24.0];
                
            default:
                return nil;
        }
    } else{
        return [[NSAttributedString alloc] initWithString:aSongInstance.songName];
    }
}

+ (BOOL)songNameIsBold
{
    return SONG_NAME_SHOULD_BE_BOLD;
}

+ (void)formatSongDetailLabelUsingSong:(Song *)aSongInstance andCell:(UITableViewCell **)aCell
{
    //now change the detail label
    [*aCell detailTextLabel].attributedText = [SongTableViewFormatter generateDetailLabelAttrStringWithArtistName:aSongInstance.artist.artistName
                                                                                                     andAlbumName:aSongInstance.album.albumName];
    [*aCell detailTextLabel].font = [UIFont systemFontOfSize:[SongTableViewFormatter songDetailLabelfontSize]];

}

+ (float)songLabelFontSize
{
    short size = [AppEnvironmentConstants preferredSizeSetting];
    
    switch (size)
    {
        case 1:
            return 15.0;
            
        case 2:
            return 17.0;
            
        case 3:  //default app setting when app launched for the first time.
            return 19.0;
            
        case 4:
            return 20.0;
            
        case 5:
            return 26.0;
            
        default:
            return -1;
    }
}

+ (float)songDetailLabelfontSize
{
    short size = [AppEnvironmentConstants preferredSizeSetting];
    
    switch (size)
    {
        case 1:
            return 12.0;
            
        case 2:
            return 14.0;
            
        case 3:  //default app setting when app launched for the first time.
            return 15.0;
            
        case 4:
            return 17.0;
            
        case 5:
            return 19.0;
            
        default:
            return -1;
    }
}

+ (float)preferredSongCellHeight
{
    short size = [AppEnvironmentConstants preferredSizeSetting];
    
    switch (size)
    {
        case 1:
            return 45.0;
            
        case 2:
            return 50.0;
            
        case 3:  //default app setting when app launched for the first time.
            return 65.0;
            
        case 4:
            return 80.0;
            
        case 5:
            return 95.0;
            
        default:
            return -1;
    }
}

+ (CGSize)preferredSongAlbumArtSize
{
    short size = [AppEnvironmentConstants preferredSizeSetting];
    
    switch (size)
    {
        case 1:
            return CGSizeMake(40, 40);
            
        case 2:
            return CGSizeMake(40, 40);
            
        case 3:  //default app setting when app launched for the first time.
            return CGSizeMake(55, 55);
            
        case 4:
            return CGSizeMake(70, 70);
            
        case 5:
            return CGSizeMake(70, 70);
            
        default:
            return CGSizeMake(-1, -1);
    }
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
