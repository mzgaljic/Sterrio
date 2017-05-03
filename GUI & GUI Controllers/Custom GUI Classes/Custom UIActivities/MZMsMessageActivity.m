//
//  MZMsMessageActivity.m
//  Sterrio
//
//  Created by Mark Zgaljic on 9/24/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import "MZMsMessageActivity.h"
#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>
#import "AppEnvironmentConstants.h"


@interface MZMsMessageActivity ()
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) UIImage *thumbnail;
@end
@implementation MZMsMessageActivity

- (instancetype)initWithUrl:(NSURL *)url thumbnailImage:(UIImage *)thumbnail
{
    NSAssert(url != nil, @"Cannot share a nil url.");
    if(self = [super init]) {
        _url = url;
        _thumbnail = thumbnail;
    }
    return self;
}

- (void)dealloc
{
    _url = nil;
    _thumbnail = nil;
}

- (NSString *)activityType
{
    return @"Sterrio.message";
}

- (NSString *)activityTitle
{
    return @"Message";
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    return YES;
}

- (void)performActivity
{
    NSAssert([AppEnvironmentConstants isUserOniOS10OrHigher], @"MZMsMessageActivity needs ios10+");
    if([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *messageController = [MFMessageComposeViewController new];
        MSMessageTemplateLayout *layoutTemplate = [MSMessageTemplateLayout new];
        [layoutTemplate setImage:_thumbnail];
        [layoutTemplate setCaption:@"The Greatest"];
        [layoutTemplate setTrailingCaption:@"Sia"];
        [layoutTemplate setSubcaption:@"Sterrio"];
        [layoutTemplate setMediaFileURL:_url];
        MSMessage *message = [MSMessage new];
        message.URL = _url;
        message.layout = layoutTemplate;
        [messageController setMessage:message];
        
        [[MZCommons topViewController] presentViewController:messageController
                                                    animated:YES
                                                  completion:nil];
    } else {
#warning show error to user
    }
    [self activityDidFinish:YES];
}

@end
