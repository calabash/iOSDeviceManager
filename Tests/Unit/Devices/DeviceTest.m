
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

@end

SpecBegin(DeviceTest)

context(@"#xctestBundlePathForTestRunnerAtPath:", ^{

  __block Device *device;
  __block NSString *testRunnerPath;
  __block NSString *actual;
  __block NSString *expected;

  before(^{
    device = [Device new];
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
