//
//  EmailComposerManager.h
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/30/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

typedef enum{
    Email_Compose_Purpose_SimpleBugReport,
    Email_Compose_Purpose_ScreenshotBugReport,
    Email_Compose_Purpose_General_Feedback
} Email_Compose_Purpose;

@interface EmailComposerManager : NSObject
                                    <MFMailComposeViewControllerDelegate,
                                    UIImagePickerControllerDelegate,
                                    UINavigationControllerDelegate>

- (instancetype)initWithEmailComposePurpose:(Email_Compose_Purpose)purpose
                                  callingVc:(UIViewController *)vc;
- (void)presentEmailComposerAndOrPhotoPicker;

@end
