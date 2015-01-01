//
//  SDCAlertView+DuplicateAlertsPreventer.h
//  Muzic
//
//  Created by Mark Zgaljic on 12/31/14.
//  Copyright (c) 2014 Mark Zgaljic. All rights reserved.
//

#import "SDCAlertView.h"

@interface SDCAlertView (DuplicateAlertsPreventer)

- (id)initWithTitle:(NSString *)title
            message:(NSString *)msg
           delegate:(id)delegate
  cancelButtonTitle:(NSString *)cancelBtnTitle
    avoidDuplicates:(BOOL)avoid;

@end
