
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
        //TODO
    }
}

- (void)testResignWithDifferentIdentity {
    if (device_available()) {
        //TODO
    }
}

- (void)testCodesignFBCodesignProviderImplementation {
    if (device_available()) {
        //TODO
    }
}

@end
