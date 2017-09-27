
#import "TestCase.h"
#import "XCTestConfigurationProxy.h"

@interface XCTestConfigurationProxyTest : TestCase

@end

@implementation XCTestConfigurationProxyTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (NSString *)xcode9Config {
    NSString *resourceDir = [[Resources shared] resourcesDirectory];
    NSString *configDir = [resourceDir stringByAppendingPathComponent:@"xctestconfigurations"];
    return [configDir stringByAppendingPathComponent:@"xcode9.xctestconfiguration"];
}

- (NSString *)xcode8Config {
    NSString *resourceDir = [[Resources shared] resourcesDirectory];
    NSString *configDir = [resourceDir stringByAppendingPathComponent:@"xctestconfigurations"];
    return [configDir stringByAppendingPathComponent:@"xcode8.xctestconfiguration"];
}

- (void)testConfigurationWithContentsOfFile {
    XCTestConfigurationProxy *config;
    
    NSString *path = [self xcode9Config];
    config = [XCTestConfigurationProxy configurationWithContentsOfFile:path];
    expect(config).notTo.equal(nil);
    
    path = [self xcode8Config];
    config = [XCTestConfigurationProxy configurationWithContentsOfFile:path];
    expect(config).notTo.equal(nil);

    path = [[Resources shared] plistPath:tasky(SIM)];
    config = [XCTestConfigurationProxy configurationWithContentsOfFile:path];
}

- (void)testDescription {
    NSString *path = [self xcode9Config];
    XCTestConfigurationProxy *config;
    config = [XCTestConfigurationProxy configurationWithContentsOfFile:path];
    
    NSLog(@"%@", config);
}

- (void)testWriteToFile {
    NSString *dir = [[Resources shared] tmpDirectoryWithName:@"xctestconfiguration"];
    NSString *path = [dir stringByAppendingPathComponent:@"XTC.plist"];
    
    NSString *configFile = [self xcode9Config];
    XCTestConfigurationProxy *config;
    config = [XCTestConfigurationProxy configurationWithContentsOfFile:configFile];
    expect([config writeToPlistFile:path overwrite:YES]).to.equal(YES);
}

@end
