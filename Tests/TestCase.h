#import "Resources.h"
#import <XCTest/XCTest.h>
#import "DeviceUtils.h"

#define testAppID [[Resources shared] TestAppIdentifier]
#define testApp( platform )  [[Resources shared] TestAppPath:platform]
#define taskyAppID [[Resources shared] TaskyIdentifier]
#define tasky( platform ) [[Resources shared] TaskyPath:platform]
#define runner( platform ) [[Resources shared] DeviceAgentPath:platform]
#define xctest( platform ) [[Resources shared] DeviceAgentXCTestPath:platform]
#define uniqueFile() [[Resources shared] uniqueFileToUpload]
#define defaultSimUDID [DeviceUtils defaultSimulatorID]
#define defaultDeviceUDID [DeviceUtils defaultPhysicalDeviceIDEnsuringOnlyOneAttached:NO]

NS_INLINE BOOL device_available() {
    if ([[Resources shared] isCompatibleDeviceConnected]) {
        return YES;
    } else {
        NSLog(@"No compatible device connected; skipping test");
        return NO;
    }
}


@interface TestCase : XCTestCase

@property(strong, readonly) Resources *resources;

- (BOOL)fileExists:(NSString *)path;

@end
