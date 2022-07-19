#import <Foundation/Foundation.h>
#import "DeviceUtils.h"
#import "XcodeUtils.h"
#import "TestCase.h"

@interface DeviceUtilsTest : TestCase

@end

@implementation DeviceUtilsTest

- (void)testXcode9DefaultSimulator {
    id MockXcodeUtils = OCMClassMock([XcodeUtils class]);
    OCMStub([MockXcodeUtils versionMajor]).andReturn(9);
    OCMStub([MockXcodeUtils versionMinor]).andReturn(4);
    
    NSString *actualName = [DeviceUtils defaultSimulator];
    NSString *expectedName = @"iPhone 8 (11.4)";
    expect(actualName).to.equal(expectedName);
}

- (void)testXcode101DefaultSimulator {
    id MockXcodeUtils = OCMClassMock([XcodeUtils class]);
    OCMStub([MockXcodeUtils versionMajor]).andReturn(10);
    OCMStub([MockXcodeUtils versionMinor]).andReturn(1);
    
    NSString *actualName = [DeviceUtils defaultSimulator];
    NSString *expectedName = @"iPhone XS (12.1)";
    expect(actualName).to.equal(expectedName);
}

- (void)testXcode102DefaultSimulator {
    id MockXcodeUtils = OCMClassMock([XcodeUtils class]);
    OCMStub([MockXcodeUtils versionMajor]).andReturn(10);
    OCMStub([MockXcodeUtils versionMinor]).andReturn(2);
    
    NSString *actualName = [DeviceUtils defaultSimulator];
    NSString *expectedName = @"iPhone Xs (12.2)";
    expect(actualName).to.equal(expectedName);
}

- (void)testXcode11DefaultSimulator {
    id MockXcodeUtils = OCMClassMock([XcodeUtils class]);
    OCMStub([MockXcodeUtils versionMajor]).andReturn(11);
    OCMStub([MockXcodeUtils versionMinor]).andReturn(7);
    
    NSString *actualName = [DeviceUtils defaultSimulator];
    NSString *expectedName = @"iPhone 11 (13.7)";
    expect(actualName).to.equal(expectedName);
}

- (void)testXcode12DefaultSimulator {
    id MockXcodeUtils = OCMClassMock([XcodeUtils class]);
    OCMStub([MockXcodeUtils versionMajor]).andReturn(12);
    OCMStub([MockXcodeUtils versionMinor]).andReturn(0);
    
    NSString *actualName = [DeviceUtils defaultSimulator];
    NSString *expectedName = @"iPhone 12 (14.0)";
    expect(actualName).to.equal(expectedName);
}

@end
