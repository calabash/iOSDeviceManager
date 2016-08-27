
#import "TestCase.h"
#import "BundleResignerFactory.h"
#import "BundleResigner.h"
#import "Codesigner.h"

@interface ResignTest : TestCase

@end

@implementation ResignTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testResignWithSameIdentity {
    if (device_available()) {
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
    }
}

- (void)testResignWithDifferentIdentity {
    if (device_available()) {
        NSString *identity = @"iPhone Developer: Joshua Moody (8QEQJFT59F)";
        NSString *deviceUDID = defaultDeviceUDID;
        NSString *bundlePath = runner(ARM);

        NSString *directory = [self.resources tmpDirectoryWithName:@"RunnerARM"];
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
    }
}

- (void)testCodesignFBCodesignProviderImplementation {
    if (device_available()) {
        NSString *identity = @"iPhone Developer: Joshua Moody (8QEQJFT59F)";
        NSString *deviceUDID = defaultDeviceUDID;
        NSString *bundlePath = runner(ARM);

        NSError *error;
        Codesigner *signer;
        signer = [[Codesigner alloc] initWithCodeSignIdentity:identity
                                                   deviceUDID:deviceUDID];

        BOOL actual = [signer signBundleAtPath:bundlePath error:&error];
        expect(actual).to.equal(YES);
    }
}

@end
