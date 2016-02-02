//
//  MZAlbumSectionHeader.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 3/24/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "MZAlbumSectionHeader.h"
#import "AlbumAlbumArt+Utilities.h"
#import "CCColorCube.h"
#import "NSString+WhiteSpace_Utility.h"
#import "Album+Utilities.h"
#import "SDCAlertController.h"

@interface MZAlbumSectionHeader ()
{
    UIView *blurredBaseView;
    UIView *gradientView;
    Album *album;
}
@property(nonatomic, strong) UITextField *titleTextField;
@end
@implementation MZAlbumSectionHeader
const short ALBUM_ART_EDGE_PADDING = 5;
const short LABEL_PADDING_FROM_ART = 10;
const short ALBUM_NAME_FONT_SIZE = 25;
const short DETAIL_LABEL_FONT_SIZE = 17;
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
    _titleTextField.delegate = nil;
    _titleTextField = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//manually rotate the subviews (or in this case redraw them since the gradient
//shouldnt be stretched).
- (void)orientationChanged
{
    //capture the users currently selected range so it doesn't get lost.
    BOOL userWasEditingTitle = _titleTextField.isEditing;
    NSRange selectedRange;
    if(userWasEditingTitle) {
        UITextRange *selectedTextRange = _titleTextField.selectedTextRange;
        NSUInteger location = [_titleTextField offsetFromPosition:_titleTextField.beginningOfDocument
                                                       toPosition:selectedTextRange.start];
        NSUInteger length = [_titleTextField offsetFromPosition:selectedTextRange.start
                                                     toPosition:selectedTextRange.end];
        selectedRange = NSMakeRange(location, length);
    }
    
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
    
    if(userWasEditingTitle) {
        [_titleTextField becomeFirstResponder];
        
        //reset the cursor position back to its original location so user isn't confused.
        UITextPosition *start = [_titleTextField positionFromPosition:[_titleTextField beginningOfDocument]
                                                               offset:selectedRange.location];
        UITextPosition *end = [_titleTextField positionFromPosition:start
                                                             offset:selectedRange.length];
        [_titleTextField setSelectedTextRange:[_titleTextField textRangeFromPosition:start toPosition:end]];
    }
}

- (void)composeViewElementsUsingAlbum:(Album *)anAlbum
{
    int height = self.frame.size.height;
    int artSize = height - ALBUM_ART_EDGE_PADDING - ALBUM_ART_EDGE_PADDING;
    
    UIImage *albumArt;
    if(anAlbum){
        albumArt = [anAlbum.albumArt imageWithSize:CGSizeMake(artSize, artSize)];
    }
    if(albumArt == nil)
        albumArt = [UIImage imageNamed:@"Sample Album Art"];
    
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
        yOriginOffset = 10;
    }

    if(_titleTextField == nil) {
        _titleTextField = [UITextField new];
        _titleTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _titleTextField.delegate = self;
        _titleTextField.text = anAlbum.albumName;
        _titleTextField.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                               size:ALBUM_NAME_FONT_SIZE];
        _titleTextField.textColor = [UIColor blackColor];
    }
    
    [_titleTextField sizeToFit];
    int labelXVal = ALBUM_ART_EDGE_PADDING + img.frame.size.width + LABEL_PADDING_FROM_ART;
    CGRect albumLabelFrame = CGRectMake(labelXVal,
                                        img.frame.origin.y + yOriginOffset,
                                        self.frame.size.width - labelXVal - LABEL_PADDING_FROM_ART,
                                        _titleTextField.frame.size.height + _titleTextField.frame.size.height);
    [_titleTextField setFrame:albumLabelFrame];
    
    UILabel *detailLabel = [UILabel new];
    detailLabel.numberOfLines = 1;
    detailLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                       size:DETAIL_LABEL_FONT_SIZE];
    detailLabel.attributedText = [self generateDetailLabelAttributedStringForAlbum:anAlbum];
    [detailLabel sizeToFit];
    CGRect detailLabelFrame = CGRectMake(labelXVal,
                                         img.frame.origin.y +
                                         img.frame.size.height - (2 * detailLabel.frame.size.height) - (yOriginOffset/2),
                                         self.frame.size.width - labelXVal,
                                         detailLabel.frame.size.height);
    [detailLabel setFrame:detailLabelFrame];
    [detailLabel sizeToFit];
    detailLabel.textColor = [UIColor darkGrayColor];
    
    UIView *seperator = [UIView new];
    seperator.backgroundColor = [UIColor grayColor];
    seperator.frame = CGRectMake(0, height-SEPERATOR_HEIGHT, self.frame.size.width, SEPERATOR_HEIGHT);
    seperator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [blurredBaseView addSubview:img];
    [blurredBaseView addSubview:_titleTextField];
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
    
    NSString *fontName = [AppEnvironmentConstants boldFontName];
    [string beginEditing];
    [string addAttribute:NSFontAttributeName
                   value:[UIFont fontWithName:fontName size:DETAIL_LABEL_FONT_SIZE]
                   range:boldRange1];
    [string addAttribute:NSFontAttributeName
                   value:[UIFont fontWithName:fontName size:DETAIL_LABEL_FONT_SIZE]
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

- (NSString *)generateTotalAlbumDurationStringUsingAlbum:(Album *)myAlbum
{
    NSUInteger totalAlbumDuration = 0;
    NSSet *songs = [myAlbum albumSongs];
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
    NSArray *imgColors = [colorCube extractColorsFromImage:image flags:CCOnlyDistinctColors];
    
    //now try to generate a gradient in code
    if(imgColors.count > 0){
        UIView *myGradientView = [[UIView alloc] initWithFrame:self.bounds];
        
        const int maxColorsInGradient = 6;
        NSMutableArray *cgColors = [NSMutableArray arrayWithCapacity:maxColorsInGradient];
        for(int i = 0; i < imgColors.count && i < maxColorsInGradient; i++) {
            UIColor *color = imgColors[i];
            [cgColors addObject:(id)color.CGColor];
        }

        CAGradientLayer *maskLayer = [CAGradientLayer layer];
        maskLayer.opacity = 1;
        maskLayer.anchorPoint = CGPointZero;
        maskLayer.bounds = self.bounds;
        maskLayer.colors = cgColors;
        maskLayer.startPoint = CGPointMake(0.0, 0.5);
        maskLayer.endPoint = CGPointMake(0.5, 1);
        maskLayer.locations = [self evenlyDistributeWithMax:1.0 min:0 arraySize:(int)cgColors.count];
        
        [myGradientView.layer addSublayer:maskLayer];
        return myGradientView;
    }
    
    return nil;
}

- (NSArray *)evenlyDistributeWithMax:(double)rangeHigh min:(double)rangeLow arraySize:(int)wanted
{
    double increment = (rangeHigh - rangeLow) / (wanted + 1);
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:wanted];
    for(double i = rangeLow + increment; i < rangeHigh; i += increment) {
        [values addObject:[NSNumber numberWithDouble:i]];
    }
    return values;
}

#pragma mark - Album Title UITextField Delegate callbacks
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    __weak NSString *prevAlbumName = album.albumName;
    NSString *newAlbumName = textField.text;
    [newAlbumName removeIrrelevantWhitespace];
    
    if(newAlbumName.length > 0 && ![album.albumName isEqualToString:newAlbumName]) {
        album.albumName = newAlbumName;
        album.smartSortAlbumName = [newAlbumName regularStringToSmartSortString];
        //edge case, if name is something like 'the', dont remove all characters! Keep original name.
        if(album.smartSortAlbumName.length == 0) {
            album.smartSortAlbumName = newAlbumName;
        }
        
        NSError *error;
        if ([[CoreDataManager context] save:&error] == NO) {
            //save failed
            NSString *title = @"Save Error";
            NSString *msg = @"Something bad happened when saving the album name.";
            SDCAlertController *alert =[SDCAlertController alertControllerWithTitle:title
                                                                            message:msg
                                                                     preferredStyle:SDCAlertControllerStyleAlert];
            SDCAlertAction *okAction = [SDCAlertAction actionWithTitle:@"OK"
                                                                 style:SDCAlertActionStyleRecommended
                                                               handler:nil];
            [alert addAction:okAction];
            __weak UITextField *weakTitleTxtField = _titleTextField;
            [alert presentWithCompletion:^{
                [weakTitleTxtField setText:prevAlbumName];
            }];
        } else {
            //save success, don't do anything.
        }
    }
    
    [textField endEditing:YES];
    return YES;
}
@end
