/* This SnapshotHelper class should be compatible with SnapshotHelper.swift version 1.2 */
@import Foundation;
@import XCTest;

@interface SnapshotHelper : NSObject

- (instancetype)initWithApp:(XCUIApplication*)app;

- (void)snapshot:(NSString*)name waitForLoadingIndicator:(BOOL)wait;

@end
