//
//  TermsOfServiceViewController.h
//  Sterrio
//
//  Created by Mark Zgaljic on 3/20/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MyViewController.h"

/**
 * Intended to be used only on devices running 8.0...since they don't support SFSafariViewController.
 */
@interface TermsOfServiceViewController : MyViewController <UIWebViewDelegate>

- (void)dismiss;

@end
