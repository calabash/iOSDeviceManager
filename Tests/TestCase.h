#import "Resources.h"
#import <XCTest/XCTest.h>

#define testAppID [[Resources shared] TestAppIdentifier]
#define testApp( platform )  [[Resources shared] TestAppPath:platform]
#define taskyAppID [[Resources shared] TaskyIdentifier]
#define tasky( platform ) [[Resources shared] TaskyPath:platform]
#define runner( platform ) [[Resources shared] DeviceAgentPath:platform]
#define xctest( platform ) [[Resources shared] DeviceAgentXCTestPath:platform]
#define defaultSim [[Resources shared] defaultSimulator]
#define defaultSimUDID [[Resources shared] defaultSimulatorUDID]
#define defaultDevice [[Resources shared] defaultDevice]
#define defaultDeviceUDID [[Resources shared] defaultDeviceUDID]
#define uniqueFile() [[Resources shared] uniqueFileToUpload]

NS_INLINE BOOL device_available() {
    if ([[Resources shared] isCompatibleDeviceConnected]) {
        return YES;
    } else {
        DDLogInfo(@"No compatible device connected; skipping test");
        return NO;
    }
}


@interface TestCase : XCTestCase

@property(strong, readonly) Resources *resources;

- (BOOL)fileExists:(NSString *)path;

@end
