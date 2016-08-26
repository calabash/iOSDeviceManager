
#import "TestCase.h"
#import "BundleResignerFactory.h"
#import "BundleResigner.h"

@interface BundleResignerFactoryTest : TestCase

@end

@implementation BundleResignerFactoryTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testResignerWithBundlePath {
    NSString *identity = @"iPhone Developer: Karl Krukow (YTTN6Y2QS9)";
    NSString *deviceUDID = defaultDeviceUDID;
    NSString *bundlePath = tasky(ARM);

    NSString *directory = [self.resources tmpDirectoryWithName:@"TaskyARM"];
    NSString *target = [directory stringByAppendingPathComponent:[bundlePath lastPathComponent]];
    [self.resources copyDirectoryWithSource:bundlePath
                                     target:target];

    bundlePath = target;

    BundleResigner *resigner;
    resigner = [[BundleResignerFactory shared]
                                       resignerWithBundlePath:bundlePath
                                                   deviceUDID:deviceUDID
                                        signingIdentityString:identity];
    expect([resigner resign]).to.equal(YES);

    identity = @"iPhone Developer: Joshua Moody (8QEQJFT59F)";
    deviceUDID = defaultDeviceUDID;
    bundlePath = runner(ARM);

    directory = [self.resources tmpDirectoryWithName:@"RunnerARM"];
    target = [directory stringByAppendingPathComponent:[bundlePath lastPathComponent]];
    [self.resources copyDirectoryWithSource:bundlePath
                                     target:target];

    bundlePath = target;
    resigner = [[BundleResignerFactory shared]
                                       resignerWithBundlePath:bundlePath
                                                   deviceUDID:deviceUDID
                                        signingIdentityString:identity];
    expect([resigner resign]).to.equal(YES);
}

@end
