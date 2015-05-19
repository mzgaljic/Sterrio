//
//  AdvancedOptionsTableViewController.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 5/3/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "AdvancedOptionsTableViewController.h"
#import "PreferredFontSizeUtility.h"
#import <MSCellAccessory.h>

@interface AdvancedOptionsTableViewController ()
{
    UISwitch *onlyAirplayAudioSwitch;
    UIView *airplaySectionFooterView;
    UILabel *airplaySectionFooterLabel;
}
@end
@implementation AdvancedOptionsTableViewController

short const NUMBER_OF_SECTIONS = 2;
short const PLAYER_AIRPLAY_OPTIONS_SECTION_NUM = 0;
short const MUSIC_LIB_SORTING_SECTION_NUM = 1;

NSString * const AIRPLAY_AUDIO_ONLY_ENABLED_FOOTER = @"Video is displayed on this device while audio is streamed to the Airplay receiver. Volume can be controlled from this device.";
NSString * const AIRPLAY_AUDIO_ONLY_DISABLED_FOOTER = @"Both video and audio are streamed to the airplay receiver. Volume control is not supported.";

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUMBER_OF_SECTIONS;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if(section == PLAYER_AIRPLAY_OPTIONS_SECTION_NUM)
    {
        if([AppEnvironmentConstants shouldOnlyAirplayAudio])
            return 95;
        else
            return 80;
    }
    else
        return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if(section == PLAYER_AIRPLAY_OPTIONS_SECTION_NUM)
    {
        //footer label length varies based on this setting.
        
        int footerViewHeight;
        NSString *footerText;
        if([AppEnvironmentConstants shouldOnlyAirplayAudio]){
            footerViewHeight = 95;
            footerText = AIRPLAY_AUDIO_ONLY_ENABLED_FOOTER;
        }else{
            footerViewHeight = 80;
            footerText = AIRPLAY_AUDIO_ONLY_DISABLED_FOOTER;
        }
        
        CGRect footerViewRect = CGRectMake(0,
                                           0,
                                           [UIScreen mainScreen].bounds.size.width,
                                           footerViewHeight);
        
        airplaySectionFooterView = [[UIView alloc] initWithFrame:footerViewRect];
        CGRect viewRect = airplaySectionFooterView.frame;
        float labelWidth = viewRect.size.width * 0.9;
        float labelHeight = viewRect.size.height * 0.9;
        int topPadding = 4;
        CGRect labelRect = CGRectMake((viewRect.size.width - labelWidth)/2,
                                      topPadding,
                                      labelWidth,
                                      labelHeight);
        airplaySectionFooterLabel = [[UILabel alloc] initWithFrame:labelRect];
        airplaySectionFooterLabel.text = footerText;
        airplaySectionFooterLabel.numberOfLines = 0;
        airplaySectionFooterLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                         size:18];
        airplaySectionFooterLabel.textColor = [UIColor grayColor];
        airplaySectionFooterLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        [airplaySectionFooterView addSubview:airplaySectionFooterLabel];
        return airplaySectionFooterView;
    }
    else
        return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section)
    {
        case PLAYER_AIRPLAY_OPTIONS_SECTION_NUM     :
        {
            if([AppEnvironmentConstants shouldOnlyAirplayAudio])
                return AIRPLAY_AUDIO_ONLY_ENABLED_FOOTER;
            else
                return AIRPLAY_AUDIO_ONLY_DISABLED_FOOTER;
        }
        case MUSIC_LIB_SORTING_SECTION_NUM          :   return nil;
            
        default:    return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PreferredFontSizeUtility recommendedRowHeightForCellWithSingleLabel];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case PLAYER_AIRPLAY_OPTIONS_SECTION_NUM     :   return 1;
        case MUSIC_LIB_SORTING_SECTION_NUM          :   return 1;
            
        default:    return -1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if(indexPath.section == PLAYER_AIRPLAY_OPTIONS_SECTION_NUM)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"advancedSettingRightDetailCell"
                                               forIndexPath:indexPath];
        
        if(indexPath.row == 0)
        {
          //streaming video during airplay
            
            cell.textLabel.text = @"Audio-Only Airplay";
            cell.detailTextLabel.text = nil;
            if(onlyAirplayAudioSwitch == nil){
                onlyAirplayAudioSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
                BOOL switchShouldBeOn = [AppEnvironmentConstants shouldOnlyAirplayAudio];
                [onlyAirplayAudioSwitch setOn:switchShouldBeOn animated:NO];
                
                [onlyAirplayAudioSwitch addTarget:self
                                           action:@selector(videoDuringAirplaySwitchToggled)
                                 forControlEvents:UIControlEventValueChanged];
            }
            
            [onlyAirplayAudioSwitch setOnTintColor:[[UIColor defaultAppColorScheme] lighterColor]];
            cell.accessoryView = onlyAirplayAudioSwitch;
            UIImage *cloudImg = [UIImage colorOpaquePartOfImage:[UIColor defaultAppColorScheme]
                                                               :[UIImage imageNamed:@"airplay settings"]];
            cell.imageView.image = cloudImg;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    else if(indexPath.section == MUSIC_LIB_SORTING_SECTION_NUM)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"advancedSettingRightDetailCell"
                                               forIndexPath:indexPath];
        
        if(indexPath.row == 0)
        {
            //ignored prefixes when sorting library cell.
            
            cell.textLabel.text = @"Alphabetical Sorting Rules";
            cell.detailTextLabel.text = nil;
            
            UIImage *sortingImg = [UIImage colorOpaquePartOfImage:[UIColor defaultAppColorScheme]
                                                                 :[UIImage imageNamed:@"sorting"]];
            cell.imageView.image = sortingImg;
            
            short flatIndicator = FLAT_DISCLOSURE_INDICATOR;
            UIColor *appTheme = [UIColor defaultAppColorScheme];
            MSCellAccessory *coloredDisclosureIndicator = [MSCellAccessory accessoryWithType:flatIndicator
                                                                                       color:appTheme];
            cell.accessoryView = coloredDisclosureIndicator;
        }
    }
    
    float fontSize = [PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize];
    cell.textLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                          size:fontSize];
    cell.detailTextLabel.font = [UIFont fontWithName:[AppEnvironmentConstants regularFontName]
                                                size:fontSize];
    cell.textLabel.numberOfLines = 2;
    cell.detailTextLabel.numberOfLines = 1;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Helpers
- (void)videoDuringAirplaySwitchToggled
{
    if(onlyAirplayAudioSwitch.isOn == [AppEnvironmentConstants shouldOnlyAirplayAudio])
        return;
    
    [AppEnvironmentConstants setShouldOnlyAirplayAudio:onlyAirplayAudioSwitch.isOn];
    
    //force footer heights to animate
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    //animate (fade) new section footer text
    CATransition *animation = [CATransition animation];
    animation.duration = 0.85;
    animation.type = kCATransitionFade;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    if([AppEnvironmentConstants shouldOnlyAirplayAudio])
        airplaySectionFooterLabel.text = AIRPLAY_AUDIO_ONLY_ENABLED_FOOTER;
    else
        airplaySectionFooterLabel.text = AIRPLAY_AUDIO_ONLY_DISABLED_FOOTER;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self updateAirplaySectionFooterFrame];
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)updateAirplaySectionFooterFrame
{
    int footerViewHeight;
    NSString *footerText;
    if([AppEnvironmentConstants shouldOnlyAirplayAudio])
        footerViewHeight = 95;
    else
        footerViewHeight = 80;

    int rowHeight = [PreferredFontSizeUtility recommendedRowHeightForCellWithSingleLabel];
    int headerHeight = 30;
    int yOrigin = rowHeight + headerHeight;
    [UIView animateWithDuration:0.3 animations:^{
        airplaySectionFooterView.frame = CGRectMake(0,
                                                    yOrigin,
                                                    [UIScreen mainScreen].bounds.size.width,
                                                    footerViewHeight);
    }];

    CGRect viewRect = airplaySectionFooterView.frame;
    float labelWidth = viewRect.size.width * 0.9;
    float labelHeight = viewRect.size.height * 0.9;
    int topPadding = 4;
    CGRect labelRect = CGRectMake((viewRect.size.width - labelWidth)/2,
                                  topPadding,
                                  labelWidth,
                                  labelHeight);
    [UIView animateWithDuration:0.3 animations:^{
        airplaySectionFooterLabel.frame = labelRect;
    }];
}

@end
