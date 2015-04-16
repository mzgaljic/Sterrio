//
//  MZAlbumSectionHeader.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/24/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZAlbumSectionHeader.h"

@interface MZAlbumSectionHeader ()
{
    UIView *blurredBaseView;
}
@end
@implementation MZAlbumSectionHeader
const short ALBUM_ART_EDGE_PADDING = 10;
const short LABEL_PADDING_FROM_ART = 15;
const short ALBUM_NAME_FONT_SIZE = 26;
const short DETAIL_LABEL_FONT_SIZE = 18;
const float SEPERATOR_HEIGHT = 0.5;

- (instancetype)initWithFrame:(CGRect)frame album:(Album *)anAlbum
{
    if(self = [super initWithFrame:frame]){
        
        UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        UIVisualEffectView *blurredView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurredView.frame = CGRectMake(0,
                                       0,
                                       self.frame.size.width,
                                       self.frame.size.height - SEPERATOR_HEIGHT);
        blurredView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        blurredBaseView = blurredView;
        [self addSubview:blurredBaseView];
        
        [self composeViewElementsUsingAlbum:anAlbum];
        anAlbum = nil;
    }
    return self;
}

- (void)composeViewElementsUsingAlbum:(Album *)anAlbum
{
    int height = self.frame.size.height;
    int artSize = height - ALBUM_ART_EDGE_PADDING - ALBUM_ART_EDGE_PADDING;
    
    NSURL *artUrl = [AlbumArtUtilities albumArtFileNameToNSURL:anAlbum.albumArtFileName];
    UIImage *albumArt = [UIImage imageWithData:[NSData dataWithContentsOfURL:artUrl]];
    
    UIImageView *img = [[UIImageView alloc] initWithImage:albumArt];
    img.contentMode = UIViewContentModeScaleAspectFit;
    if(albumArt){
        img.frame = CGRectMake(ALBUM_ART_EDGE_PADDING,
                               ALBUM_ART_EDGE_PADDING,
                               artSize,
                               artSize);
    } else{
        img.frame = CGRectMake(ALBUM_ART_EDGE_PADDING,
                               ALBUM_ART_EDGE_PADDING,
                               0,
                               artSize);
    }
    
    
    short yOriginOffset = 0;
    //calculate how much one length varies from the other.
    int diff = abs((int)albumArt.size.width - (int)albumArt.size.height);
    if(diff > 0){
        //aspect ratio is aspect FIT, which means in this case, the img y origin wont
        //be the same as where the image appears the being (since the image is wide here)
        yOriginOffset = 18;
    }

    UILabel *albumLabel = [UILabel new];
    albumLabel.numberOfLines = 1;
    albumLabel.text = anAlbum.albumName;
    albumLabel.font = [UIFont fontWithName:[AppEnvironmentConstants boldFontName]
                                      size:ALBUM_NAME_FONT_SIZE];
    [albumLabel sizeToFit];
    int labelXVal = ALBUM_ART_EDGE_PADDING + img.frame.size.width + LABEL_PADDING_FROM_ART;
    CGRect albumLabelFrame = CGRectMake(labelXVal,
                                        img.frame.origin.y + yOriginOffset,
                                        self.frame.size.width - labelXVal,
                                        albumLabel.frame.size.height);
    [albumLabel setFrame:albumLabelFrame];
    albumLabel.textColor = [UIColor blackColor];
    
    UILabel *detailLabel = [UILabel new];
    detailLabel.numberOfLines = 1;
    detailLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                       size:DETAIL_LABEL_FONT_SIZE];
    detailLabel.attributedText = [self generateDetailLabelAttributedStringForAlbum:anAlbum];
    [detailLabel sizeToFit];
    CGRect detailLabelFrame = CGRectMake(labelXVal,
                                         img.frame.origin.y +
                                         img.frame.size.height - (2 * detailLabel.frame.size.height),
                                         self.frame.size.width - labelXVal,
                                         detailLabel.frame.size.height);
    [detailLabel setFrame:detailLabelFrame];
    detailLabel.textColor = [UIColor darkGrayColor];
    
    UIView *seperator = [UIView new];
    seperator.backgroundColor = [UIColor grayColor];
    seperator.frame = CGRectMake(0, height-SEPERATOR_HEIGHT, self.frame.size.width, SEPERATOR_HEIGHT);
    seperator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [blurredBaseView addSubview:img];
    [blurredBaseView addSubview:albumLabel];
    [blurredBaseView addSubview:detailLabel];
    [blurredBaseView addSubview:seperator];
}

#pragma mark - generating detail label attributed string
- (NSAttributedString *)generateDetailLabelAttributedStringForAlbum:(Album *)anAlbum
{
    NSString *totalDurationString = [self generateTotalAlbumDurationStringUsingAlbum:anAlbum];
    NSMutableString *detailText = [NSMutableString string];
    [detailText appendString:[self generateAlbumSongCountStringUsingCount:anAlbum.albumSongs.count]];
    [detailText appendString:@", "];
    [detailText appendString:[NSString stringWithFormat:@"%@ min", totalDurationString]];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:detailText];
    int lengthOfSongIntAsString = (int)[NSString stringWithFormat:@"%lu",
                                   (unsigned long)anAlbum.albumSongs.count].length;
    
    NSRange boldRange1 = NSMakeRange(0, lengthOfSongIntAsString);
    NSRange boldRange2 = [detailText rangeOfString:totalDurationString];
    
    [string beginEditing];
    [string addAttribute:NSFontAttributeName
                   value:[UIFont boldSystemFontOfSize:DETAIL_LABEL_FONT_SIZE]
                   range:boldRange1];
    [string addAttribute:NSFontAttributeName
                   value:[UIFont boldSystemFontOfSize:DETAIL_LABEL_FONT_SIZE]
                   range:boldRange2];
    [string endEditing];
    return string;
}

- (NSString *)generateAlbumSongCountStringUsingCount:(NSUInteger)numSongsValue
{
    NSString *numSongs = [NSString stringWithFormat:@"%lu", (unsigned long)numSongsValue];
    NSString *songString;
    if(numSongsValue == 1)
        songString = [NSString stringWithFormat:@"%@ song", numSongs];
    else
        songString = [NSString stringWithFormat:@"%@ songs", numSongs];
    return songString;
}

- (NSString *)generateTotalAlbumDurationStringUsingAlbum:(Album *)album
{
    NSUInteger totalAlbumDuration = 0;
    NSSet *songs = [album albumSongs];
    NSEnumerator *setEnum = [songs objectEnumerator];
    Song *aSong;
    while ((aSong = [setEnum nextObject]) != nil){
        totalAlbumDuration += [aSong.duration integerValue];
    }
    return [self convertSecondsToPrintableMinUsingSeconds:totalAlbumDuration];
}

- (NSString *)convertSecondsToPrintableMinUsingSeconds:(NSUInteger)value
{
    NSUInteger totalSeconds = value;
    NSUInteger totalMinutes = ceil(totalSeconds / MZSecondsInAMinute);
    
    return [NSString stringWithFormat:@"%lu", (unsigned long)totalMinutes];
}


@end
