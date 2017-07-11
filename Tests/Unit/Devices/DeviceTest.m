
#import "TestCase.h"
#import "Device.h"

@interface DeviceTest : TestCase

@end

@implementation DeviceTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testStartTestArguments {
    NSArray *array = [Device startTestArguments];
    expect(array.count).to.equal(4);
    expect(array).to.contain(@"-NSTreatUnknownArgumentsAsOpen");
    expect(array).to.contain(@"NO");
    expect(array).to.contain(@"-ApplePersistenceIgnoreState");
    expect(array).to.contain(@"YES");
}

- (void)testStartTestEnvironment {
    NSDictionary *dictionary = [Device startTestEnvironment];
    expect(dictionary.count).to.equal(1);
    expect(dictionary[@"XCTestConfigurationFilePath"]).to.equal(@"thanksforusingcalabash");
}

- (void)testFBiOSDeviceOperatorProvidesMethodForApplicationAttributes {
    NSDictionary *dictionary = [FBiOSDeviceOperator applicationReturnAttributesDictionary];
    NSArray *attrs = dictionary[@"ReturnAttributes"];
    expect(attrs).to.contain(@"CFBundleIdentifier");
    expect(attrs).to.contain(@"Path");
    expect(attrs).to.contain(@"Container");
}

@end

SpecBegin(DeviceTest)

__block Device *device;

before(^{
    device = [Device new];
});

context(@"#xctestBundlePathForTestRunnerAtPath:", ^{

    __block NSString *testRunnerPath;
    __block NSString *actual;
    __block NSString *expected;

    before(^{
        testRunnerPath = @"";
        actual = nil;
        expected = nil;
    });

    it(@"returns nil if test runner path does not end in -Runner.app", ^{
        testRunnerPath = @"some/other/AppBundle.app";
        actual = [device xctestBundlePathForTestRunnerAtPath:testRunnerPath];
        expect(actual).to.equal(nil);
    });

    it(@"returns nil if test runner path does not split into 2 tokens on -Runner.app", ^{
        testRunnerPath = @"some/other/AppBundle-Runner.app-Runner.app";
        actual = [device xctestBundlePathForTestRunnerAtPath:testRunnerPath];
        expect(actual).to.equal(nil);
    });

    it(@"returns path to PlugIns/<RunnerName>.xctest", ^{
        testRunnerPath = @"some/Test-Runner.app";
        expected = @"some/Test-Runner.app/PlugIns/Test.xctest";
        actual = [device xctestBundlePathForTestRunnerAtPath:testRunnerPath];
        expect(actual).to.equal(expected);
    });
});

SpecEnd
