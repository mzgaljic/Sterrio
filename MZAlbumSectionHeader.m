//
//  MZAlbumSectionHeader.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/24/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZAlbumSectionHeader.h"
#import "AlbumAlbumArt+Utilities.h"
#import "ColorCube/CCColorCube.h"

@interface MZAlbumSectionHeader ()
{
    UIView *blurredBaseView;
    UIView *gradientView;
    Album *album;
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
        album = anAlbum;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationChanged)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    album = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)orientationChanged
{
    //manually rotate the subviews (or in this case redraw them since the gradient shouldnt be stretched).
    [gradientView removeFromSuperview];
    [blurredBaseView removeFromSuperview];
    
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    UIVisualEffectView *blurredView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurredView.frame = CGRectMake(0,
                                   0,
                                   self.frame.size.width,
                                   self.frame.size.height - SEPERATOR_HEIGHT);
    blurredView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    blurredBaseView = blurredView;
    [self addSubview:blurredBaseView];
    [self composeViewElementsUsingAlbum:album];
}

- (void)composeViewElementsUsingAlbum:(Album *)anAlbum
{
    int height = self.frame.size.height;
    int artSize = height - ALBUM_ART_EDGE_PADDING - ALBUM_ART_EDGE_PADDING;
    
    UIImage *albumArt;
    if(anAlbum){
        albumArt = [anAlbum.albumArt imageWithSize:CGSizeMake(artSize, artSize)];
    }
    
    //background color of view (under blurred base view)
    gradientView = [self gradientBackgroundBasedOnAlbumArtImage:albumArt];
    if(gradientView)
    {
        [self insertSubview:gradientView belowSubview:blurredBaseView];
    }
    
    
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

#pragma mark - color utility
- (UIView *)gradientBackgroundBasedOnAlbumArtImage:(UIImage *)image
{
    CCColorCube *colorCube = [[CCColorCube alloc] init];
    NSArray *imgColors = [colorCube extractColorsFromImage:image
                                                     flags:CCOnlyDistinctColors
                                                avoidColor:[UIColor grayColor]];
    
    //now try to generate a gradient in code
    if(imgColors.count >= 2)
    {
        UIView *gradientView = [[UIView alloc] initWithFrame:self.bounds];
        
        UIColor *color1 = imgColors[0];
        UIColor *color2 = imgColors[2];

        CAGradientLayer *maskLayer = [CAGradientLayer layer];
        maskLayer.opacity = 0.8;
        maskLayer.colors = @[(id)color1.CGColor, (id)color2.CGColor];
        
        //Hoizontal - commenting these two lines will make the gradient veritcal
        maskLayer.startPoint = CGPointMake(0.0, 0.5);
        maskLayer.endPoint = CGPointMake(1.0, 0.5);
        
        NSNumber *gradTopStart = [NSNumber numberWithFloat:0.0];
        NSNumber *gradTopEnd = [NSNumber numberWithFloat:1];
        NSNumber *gradBottomStart = [NSNumber numberWithFloat:0];
        NSNumber *gradBottomEnd = [NSNumber numberWithFloat:1.0];
        maskLayer.locations = @[gradTopStart, gradTopEnd, gradBottomStart, gradBottomEnd];
        
        maskLayer.bounds = self.bounds;
        maskLayer.anchorPoint = CGPointZero;
        [gradientView.layer addSublayer:maskLayer];
        
        return gradientView;
    }
    else if(imgColors.count == 1)
    {
        UIView *view = [[UIView alloc] initWithFrame:self.bounds];
        view.backgroundColor = imgColors[0];
        return view;
    }
    else
        return nil;
}

@end
