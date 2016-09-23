//
//  SterrioUITests.m
//  SterrioUITests
//
//  Created by Mark Zgaljic on 9/15/16.
//  Copyright © 2016 Mark Zgaljic Apps. All rights reserved.
//

#import <XCTest/XCTest.h>
@import UIKit;
#import "SnapshotHelper.h"
#import "Sterrio"

@interface SterrioUITests : XCTestCase
@property (nonatomic, strong) SnapshotHelper *snapshotHelper;
@end

@implementation SterrioUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    _snapshotHelper = [[SnapshotHelper alloc] initWithApp:app];
    [app launch];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testExample {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    
    //Songs tab
    [_snapshotHelper snapshot:@"Library" waitForLoadingIndicator:YES];
    
    XCUIElement *button = [[[[[[app childrenMatchingType:XCUIElementTypeWindow] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther] elementBoundByIndex:1] childrenMatchingType:XCUIElementTypeButton].element;
    [button tap];
    [app.tables.searchFields[@"Search"] typeText:@"let it go"];
    
    [_snapshotHelper snapshot:@"Search Results" waitForLoadingIndicator:YES];
}

@end
