
#import "TestCase.h"
#import "StringUtils.h"

@interface StringUtilsTest : TestCase

@end

@implementation StringUtilsTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testIsUniformIdentifier {
    expect([@"com.example.MyApp" isUniformTypeIdentifier]).to.beTruthy();
    expect([@"path/to/MyApp.app" isUniformTypeIdentifier]).to.beFalsy();
    // Demonstrates how an app path can be confused as bundle identifier
    expect([@"MyApp.app" isUniformTypeIdentifier]).to.beTruthy();
}

@end
