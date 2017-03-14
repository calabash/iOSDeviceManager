#import <XCTest/XCTest.h>
#import "TestUtils.h"
#import "CLI.h"

/*
 A class to extract common util functions of PhysicalDevices and Simulators.

 No `test*` methods should exist here directly, but but common `test*` methods
 can have their implementation extracted here.
 */

@interface DeviceCLIIntegrationTests : XCTestCase
@property (nonatomic, strong) NSString *deviceID;
@property (nonatomic, strong) NSString *platform; //ARM or SIM
@property (nonatomic, strong) NSString *codesignID;
@property(strong, readonly) Resources *resources;

/*
 Uninstalls app if installed. Asserts that app is not installed before returning.
 */
- (void)uninstallOrThrow:(NSString *)bundleID;

/*
 Installs if not installed. Asserts that app is installed before returning.
 */
- (void)installOrThrow:(NSString *)appPath bundleID:(NSString *)bundleID shouldUpdate:(BOOL)shouldUpdate;

/*
 YES if installed, NO if not, throws if error occurs when checking.
 */
- (BOOL)isInstalled:(NSString *)bundleID;

/*
 Returns CFBundleIdentifier
 */
- (NSString *)appBundleVersion:(NSString *)bundleID;

/*
 Calls start_test with -K NO so that it doesn't hang.
 TODO: -k YES, sleep, POST 1.0/shutdown, assert success
 */
- (iOSReturnStatusCode)startTest;


- (iOSReturnStatusCode)setLocation:(NSString *)location;

/*
 Shared tests

 These are written in an architecture agnostic way. Any arch-specific code can be handled
 by the setUp method.

 For naming conventions, if the original test is
 - (void)testFooBarBaz

 the shared test should be
 - (void)sharedFooBarBazTest

 s'il vous plait.

 */
- (void)sharedInstallTest;
- (void)sharedUninstallTest;
- (void)sharedAppUpdateTest;
- (void)sharedUploadFileTest;
- (void)sharedSetLocationTest;
- (void)sharedOptionalArgsTest;
- (void)sharedAppIsInstalledTest;
- (void)sharedPositionalArgsTest;
- (void)sharedLaunchAndKillAppTest;
- (void)sharedStopSimulatingLocationTest;
@end
