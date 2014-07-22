//
//  PreferredFontSizeUtility.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 7/21/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "PreferredFontSizeUtility.h"

@implementation PreferredFontSizeUtility

+ (float)actualLabelFontSizeFromCurrentPreferredSize
{
    if([AppEnvironmentConstants boldNames]){
        switch ([AppEnvironmentConstants preferredSizeSetting])
        {
            case 1:
                return 14.0;
                
            case 2:
                return 15.0;
                
            case 3:  //default app setting when app launched for the first time.
                return 16.0;
                
            case 4:
                return 19.0;
                
            case 5:
                return 24.0;
                
            case 6:
                return 30.0;
            default:
                return 16.0;
        }
    } else{
        switch ([AppEnvironmentConstants preferredSizeSetting])
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
                
            case 6:
                return 31.0;
            default:
                return 19.0;
        }
    }
}

+ (float)actualDetailLabelFontSizeFromCurrentPreferredSize
{
    switch ([AppEnvironmentConstants preferredSizeSetting])
    {
        case 1:
            return 13.0;
            
        case 2:
            return 14.0;
            
        case 3:  //default app setting when app launched for the first time.
            return 16.0;
            
        case 4:
            return 18.0;
            
        case 5:
            return 20.0;
            
        case 6:
            return 23.0;
        default:
            return 15.0;
    }
}

+ (float)actualCellHeightFromCurrentPreferredSize
{
    
    switch ([AppEnvironmentConstants preferredSizeSetting])
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
            
        case 6:
            return 120.0;
            
        default:
            return 65.0;
    }

}

+ (CGSize)actualAlbumArtSizeFromCurrentPreferredSize
{
    switch ([AppEnvironmentConstants preferredSizeSetting])
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
            
            
        case 6:
            return CGSizeMake(70, 70);
            
        default:
            return CGSizeMake(55, 55);
    }
}

@end
