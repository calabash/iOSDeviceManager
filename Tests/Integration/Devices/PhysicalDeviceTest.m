
#import "TestCase.h"
#import "PhysicalDevice.h"

@interface PhysicalDeviceTest : TestCase

@end

@implementation PhysicalDeviceTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInstallPathAndContainerPathForApplication {
    if (!device_available()) { return; }

    PhysicalDevice *device = [PhysicalDevice withID:defaultDeviceUDID];

    Application *app = [Application withBundlePath:testApp(ARM)];
    [device installApp:app shouldUpdate:YES];

    NSString *bundleIdentifier = @"sh.calaba.TestApp";
    NSString *installPath = [device installPathForApplication:bundleIdentifier];
    NSString *containerPath = [device containerPathForApplication:bundleIdentifier];
    NSLog(@"  install: %@", installPath);
    NSLog(@"container: %@", containerPath);

    expect(installPath).notTo.beNil;
    expect([installPath containsString:@"data/Containers/Bundle/Application"]).to.beTruthy;
    expect([installPath containsString:@"TestApp.app"]).to.beTruthy;

    expect(containerPath).notTo.beNil;
    expect([containerPath containsString:@"data/Containers/Data/Application"]).to.beTruthy;

    bundleIdentifier = @"com.example.NoSuchApp";
    installPath = [device installPathForApplication:bundleIdentifier];
    containerPath = [device containerPathForApplication:bundleIdentifier];

    expect(installPath).to.beNil;
    expect(containerPath).to.beNil;
}

@end
