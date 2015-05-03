//
//  FontSizeTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/28/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "FontSizeTableViewController.h"
#import "MZTableViewCell.h"
#import "CoreDataManager.h"
#import "Song+Utilities.h"
#import "SongAlbumArt+Utilities.h"
#import <FXImageView/UIImage+FX.h>

@interface FontSizeTableViewController ()
{
    int cellHeight;
    int cellMaxHeight;
    int cellMinHeight;
    UISlider *slider;
    UIImage *sampleAlbumArtImg;
}
@end
@implementation FontSizeTableViewController
short const FONT_SLIDER_SECTION_NUM = 0;
short const PREVIEW_SONG_SECTION_NUM = 1;

#pragma mark - lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    cellHeight = [AppEnvironmentConstants preferredSongCellHeight];
    cellMaxHeight = [AppEnvironmentConstants maximumSongCellHeight];
    cellMinHeight = [AppEnvironmentConstants minimumSongCellHeight];
    self.tableView.allowsSelection = NO;
    self.title = @"Font Size";
    slider = [[UISlider alloc] init];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [AppEnvironmentConstants setPreferredSongCellHeight:cellHeight];
}

- (void)dealloc
{
    sampleAlbumArtImg = nil;
}

#pragma mark - UITableView Data source delegate stuff
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case PREVIEW_SONG_SECTION_NUM    :   return @"Preview";
            
        default:    return @"";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == PREVIEW_SONG_SECTION_NUM)
        return cellHeight;
    else
        return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MZTableViewCell *cell;
    
    if(indexPath.section == FONT_SLIDER_SECTION_NUM)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"fontSliderCell"
                                                 forIndexPath:indexPath];

        slider.maximumValue = cellMaxHeight;
        slider.minimumValue = cellMinHeight;
        slider.value = [AppEnvironmentConstants preferredSongCellHeight];;
        slider.minimumTrackTintColor = [UIColor defaultAppColorScheme];
        slider.maximumTrackTintColor = [UIColor defaultAppColorScheme];
        
        UIFont *largeFont = [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:30];
        slider.maximumValueImage = [self imageFromText:@"A"
                                                  font:largeFont];
        
        UIFont *smallFont = [UIFont fontWithName:[AppEnvironmentConstants regularFontName] size:16];
        slider.minimumValueImage = [self imageFromText:@"A"
                                                  font:smallFont];
        
        int edgePadding = 15;
        int width = cell.contentView.frame.size.width - (2 * edgePadding);
        CGRect sliderRect = CGRectMake(edgePadding,
                                       0,
                                       width,
                                       cell.frame.size.height);
        slider.frame = sliderRect;
        
        slider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [cell.contentView addSubview:slider];

        [slider addTarget:self
                   action:@selector(sliderValueChanged)
         forControlEvents:UIControlEventValueChanged];
    }
    else if(indexPath.section == PREVIEW_SONG_SECTION_NUM)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"previewSongCell"
                                               forIndexPath:indexPath];
        
        Song *aSong = [self randomSongObjectFromModelIfPresent];
        if(aSong)
        {
            cell.textLabel.text = aSong.songName;
            cell.detailTextLabel.attributedText = [self generateDetailLabelAttrStringForArtistName:aSong.artist.artistName albumName:aSong.album.albumName];
            
            UIImage *cellImg, *albumArt;
            if(aSong.albumArt){
                albumArt = [aSong.albumArt imageFromImageData];
            }
            
            //calculate how much one length varies from the other.
            int diff = abs((int)cellImg.size.width - (int)cellImg.size.height);
            if(diff > 10){
                //image is not a perfect (or close to perfect) square. Compensate for this...
                cellImg = [albumArt imageScaledToFitSize:cell.imageView.frame.size];
            } else
                cellImg = albumArt;
            
            [UIView transitionWithView:cell.imageView
                              duration:MZCellImageViewFadeDuration
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                cell.imageView.image = cellImg;
                            } completion:nil];
            albumArt = nil;
        }
        else{
            //show sample song since user has no songs in app.
            cell.textLabel.text = @"Song Name";
            cell.detailTextLabel.attributedText = [self generateDetailLabelAttrStringForArtistName:@"Artist" albumName:@"Album"];
            
            sampleAlbumArtImg = [UIImage imageNamed:@"Sample Album Art"];
            [UIView transitionWithView:cell.imageView
                              duration:MZCellImageViewFadeDuration
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                cell.imageView.image = sampleAlbumArtImg;
                            }
                            completion:nil];
        }
    }
    
    return cell;
}

#pragma mark - Helpers
- (void)sliderValueChanged
{
    cellHeight = (int)slider.value;
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}


//only returns a song if it has album art.
- (Song *)randomSongObjectFromModelIfPresent
{
    NSManagedObjectContext *context = [CoreDataManager context];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Song"];
    
    //only return results if they have album art (otherwise we'll just show the sample song in the
    //preview tableview section.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.albumArt != $NO_ARTWORK"];
    predicate = [predicate predicateWithSubstitutionVariables:@{@"NO_ARTWORK" : [NSNull null]}];
    request.predicate = predicate;

    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"smartSortSongName"
                                                   ascending:YES
                                                    selector:@selector(localizedStandardCompare:)];
    request.sortDescriptors = @[sortDescriptor];
    NSArray *songs = [context executeFetchRequest:request error:nil];
    if(songs.count > 0)
        return songs[0];
    else
        return nil;
}

- (NSAttributedString *)generateDetailLabelAttrStringForArtistName:(NSString *)artistName
                                                         albumName:(NSString *)albumName
{
    NSString *artistString = artistName;
    NSString *albumString = albumName;
    if(artistString != nil && albumString != nil){
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
        
    } else if(artistString == nil && albumString == nil)
        return nil;
    
    else if(artistString == nil && albumString != nil){
        NSMutableString *entireString = [NSMutableString stringWithString:albumString];
        
        NSArray *components = @[albumString];
        NSRange grayRange = [entireString rangeOfString:[components objectAtIndex:0]];
        
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:entireString];
        
        [attrString beginEditing];
        [attrString addAttribute: NSForegroundColorAttributeName
                           value:[UIColor grayColor]
                           range:grayRange];
        [attrString endEditing];
        return attrString;
        
    } else if(artistString != nil && albumString == nil){
        
        NSMutableString *entireString = [NSMutableString stringWithString:artistString];
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:entireString];
        return attrString;
        
    } else  //case should never happen
        return nil;
}

- (UIImage *)imageFromText:(NSString *)text font:(UIFont *)aFont
{
    float leftSidePadding = 10;
    CGSize tempSize = [text sizeWithFont:aFont];
    CGSize size = CGSizeMake(tempSize.width + leftSidePadding, tempSize.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    [text drawAtPoint:CGPointMake(leftSidePadding, 0.0) withFont:aFont];
    
    // transfer image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
