//
//  EmailComposerManager.m
//  Free Music Library
//
//  Created by Mark Zgaljic on 4/30/15.
//  Copyright (c) 2015 Mark Zgaljic. All rights reserved.
//

#import "EmailComposerManager.h"
#import "PreferredFontSizeUtility.h"
#import <SDCAlertView.h>
#import "UIDevice+DeviceName.h"
#import "MRProgress.h"

@interface EmailComposerManager ()
@property (nonatomic, assign) Email_Compose_Purpose composePurpose;
@property (nonatomic, strong) UIImage *attachedImage;
@property (nonatomic, strong) UIImagePickerController *photoPickerController;
@property (nonatomic, strong) UIViewController *callingVc;
@end
@implementation EmailComposerManager

- (instancetype)initWithEmailComposePurpose:(Email_Compose_Purpose)purpose
                                  callingVc:(UIViewController *)vc
{
    if(self = [super init]){
        self.composePurpose = purpose;
        self.callingVc = vc;
    }
    return self;
}

- (void)presentEmailComposerAndOrPhotoPicker
{
    if(self.composePurpose == Email_Compose_Purpose_ScreenshotBugReport){
        //in this case the image picker is presented first. on its dismissal, we present the mail vc.
        self.photoPickerController = [[UIImagePickerController alloc] init];
        self.photoPickerController.delegate = self;
        //set tint color specifically for this VC so that the cancel buttons are invisible
        self.photoPickerController.view.tintColor = [UIColor defaultWindowTintColor];
        self.photoPickerController.navigationBar.barTintColor = [UIColor defaultAppColorScheme];
        [self.callingVc presentViewController:self.photoPickerController animated:YES completion:nil];
    }
    else{
        [self callMailComposer];
    }
}

- (void)dealloc
{
    self.callingVc = nil;
    self.photoPickerController = nil;
    self.attachedImage = nil;
}

- (void)callMailComposer
{
    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
    if (mailClass != nil){
        // We must always check whether the current device is configured for sending emails
        if ([mailClass canSendMail])
            [self displayComposerModalView];
        else
            [self launchMailAppOnDevice];
    }
    else
        [self launchMailAppOnDevice];
}

// Displays an email composition interface inside the application. Populates all the Mail fields.
-(void)displayComposerModalView
{
    MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
    
    //tint of buttons
    [composer.navigationBar setTintColor:[UIColor blackColor]];
    
    //title color
    composer.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor defaultAppColorScheme]};
    
    composer.mailComposeDelegate = self;
    NSString *emailSubject = [self emailSubjectForComposePurpose:self.composePurpose];
    [composer setSubject:emailSubject];
    
    // Set up recipients
    [composer setToRecipients:@[MZEmailBugReport]];
    [composer setMessageBody:[self emailBodyForComposePurpose:self.composePurpose] isHTML:NO];
    
    if(self.attachedImage){
        
        [composer addAttachmentData:UIImagePNGRepresentation(self.attachedImage)
                         mimeType:@"image/png"
                         fileName:@"My Screenshot"];
        [self.photoPickerController presentViewController:composer animated:YES completion:nil];
    }
    else
        [self.callingVc presentViewController:composer animated:YES completion:nil];

    
    if(composer)
        composer = nil;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self.callingVc setNeedsStatusBarAppearanceUpdate];
}

- (NSString *)buildCurrentEstTimeString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MM/dd/yy, hh:mmaa";
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/New_York"]];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    NSDate *date = [dateFormatter dateFromString:dateString];  //right now date is in GMT +0:00
    
    // converts date to proper time zone, returns a string
    NSMutableString *returnMe = [NSMutableString stringWithString: [dateFormatter stringFromDate:date]];
    [returnMe appendString:@" EST"];
    return returnMe;
}

// Dismisses email composition gui when users tap Cancel or Send. Then it updates the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    NSString *alertMessage;
    NSString *alertTitle;
    BOOL showEmailAlertView = NO;
    
    // Notifies users about errors associated with the interface
    switch (result)
    {
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultSaved:
            break;
        case MFMailComposeResultSent:
            if(self.composePurpose == Email_Compose_Purpose_General_Feedback){
                alertTitle = @"Feedback";
                alertMessage = @"Your email has been sent.\n\nThank you for your feedback!";
            }
            else{
                alertTitle = @"Bug Report";
                alertMessage = @"Your email has been sent.\n\nThank you for reporting the bug!";
            }
            
            showEmailAlertView = YES;
            break;
        case MFMailComposeResultFailed:
            alertTitle = @"Mail Problem";
            alertMessage = @"Failed to send email.";
            showEmailAlertView = YES;
            break;
        default:
            alertTitle = @"Mail Problem";
            alertMessage = @"Could not send your email, please try again.";
            showEmailAlertView = YES;
            break;
    }
    
    SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:alertTitle
                                             message:alertMessage
                                            delegate:self
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles: nil];
    alert.titleLabelFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    alert.messageLabelFont = [UIFont systemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    alert.suggestedButtonFont = [UIFont boldSystemFontOfSize:[PreferredFontSizeUtility actualLabelFontSizeFromCurrentPreferredSize]];
    alert.buttonTextColor = [UIColor defaultAppColorScheme];
    
    if(self.attachedImage){
        //dismiss BOTH photo picker and mail composer.
        
        [controller.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
            if(showEmailAlertView)
                [alert show];
        }];
    }
    else
        //just dismiss the mail composer, photo picker wasnt used.
        [controller dismissViewControllerAnimated:YES completion:^{
            if(showEmailAlertView)
                [alert show];
        }];
}

// Launches the Mail application on the device (when does this occur?)
- (void)launchMailAppOnDevice
{
    NSMutableString *recipients = [NSMutableString stringWithString: @"mailto:"];
    [recipients appendString:MZEmailBugReport];
    [recipients appendString:@"?cc=&subject="];
    NSString *body = @"&body=";
    NSString *email = [NSString stringWithFormat:@"%@%@", recipients, body];
    email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}


- (NSString *)emailSubjectForComposePurpose:(Email_Compose_Purpose)purpose
{
    switch (purpose)
    {
        case Email_Compose_Purpose_General_Feedback:
            return @"Feedback";
        
        case Email_Compose_Purpose_ScreenshotBugReport:
        case Email_Compose_Purpose_SimpleBugReport:
            return @"Bug Discovered";
        
        default:
            return @"";
    }
}

- (NSString *)emailBodyForComposePurpose:(Email_Compose_Purpose)purpose
{
    switch (purpose)
    {
        case Email_Compose_Purpose_General_Feedback:
        {
            return @"";
        }
            
        case Email_Compose_Purpose_SimpleBugReport:
        case Email_Compose_Purpose_ScreenshotBugReport:
        {
            //\u2022 is Unicode for a bullet
            NSString *appVersion = [UIDevice appVersionString];
            NSString *iosVersion = [[UIDevice currentDevice] systemVersion];
            NSString *buildNum = [UIDevice appBuildString];
            NSString *deviceName = [UIDevice deviceName];
            
            NSString *body = @"Name the bug:\n\nLocation of issue (in App):\n\n\nIt's OK to get in touch with me if something is unclear: (Y/N)\n\n\n~Bug Details~\nBasic Description:\n\nSteps for reproducing the bug, if possible:\n1)\n2)\n\n\n~Bug Report Info~\ntime&date\nApp Version: appVersion# (build build#)\niOS Version: iosVersion#\nDevice: deviceName#";
            
            body = [body stringByReplacingOccurrencesOfString:@"time&date" withString:[self buildCurrentEstTimeString]];
            body = [body stringByReplacingOccurrencesOfString:@"appVersion#" withString:appVersion];
            body = [body stringByReplacingOccurrencesOfString:@"iosVersion#" withString:iosVersion];
            body = [body stringByReplacingOccurrencesOfString:@"build#" withString:buildNum];
            body = [body stringByReplacingOccurrencesOfString:@"deviceName#" withString:deviceName];
            
            return body;
        }
            
        default:
            return @"";
    }
}

#pragma mark - Photo Picker Delegate stuff
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *img = [info objectForKey:UIImagePickerControllerOriginalImage];
    if(img != nil){
        self.attachedImage = img;
    }
    
    //photo picker is dismissed with the mail composer at the very end. dismissing too early looks ugly.
    [self callMailComposer];
}

@end
