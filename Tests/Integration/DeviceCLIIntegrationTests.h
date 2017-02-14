
#import <XCTest/XCTest.h>
#import "TestUtils.h"
#import "CLI.h"

/*
 A class to extract common util functions of PhysicalDevices and Simulators.
 NO ACTUAL TESTS SHOULD EXIST HERE.
 */

@interface DeviceCLIIntegrationTests : XCTestCase
@property (nonatomic, strong) NSString *deviceID;
- (void)ensureUninstalled:(NSString *)bundleID;
- (void)ensureInstalled:(NSString *)bundleID;

- (iOSReturnStatusCode)startTest;
@end
