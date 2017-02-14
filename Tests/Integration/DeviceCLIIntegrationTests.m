
#import "DeviceCLIIntegrationTests.h"

@interface DeviceCLIIntegrationTests()

@end

@implementation DeviceCLIIntegrationTests

- (void)setUp {
    [[Resources shared] setDeveloperDirectory];
    [Simctl shared];
    [super setUp];
}

- (void)ensureUninstalled:(NSString *)bundleID {
    NSArray *args = @[
                      kProgramName, @"is_installed",
                      @"-b", bundleID,
                      @"-d", self.deviceID
                      ];
    
    iOSReturnStatusCode installedRC = [CLI process:args];
    if (installedRC == iOSReturnStatusCodeEverythingOkay) {
        args = @[
                 kProgramName, @"uninstall",
                 @"-d", self.deviceID,
                 @"-b", bundleID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    } else {
        XCTAssertEqual(installedRC, iOSReturnStatusCodeFalse);
    }
}

- (iOSReturnStatusCode)startTest {
    NSArray *args = @[kProgramName, @"start_test",
                      @"-d", self.deviceID,
                      @"-k", @"NO"];
    return [CLI process:args];
}

@end
