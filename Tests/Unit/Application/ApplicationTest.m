
#import "TestCase.h"
#import "Application.h"

@interface ApplicationTest : TestCase

@end

@implementation ApplicationTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testAppBundleOrIpaArchiveExistsAtPath {

    NSString *path = testApp(SIM);
    expect([Application appBundleOrIpaArchiveExistsAtPath:path]).to.beTruthy();

    path = [[Resources shared] TaskyIpaPath];
    expect([Application appBundleOrIpaArchiveExistsAtPath:path]).to.beTruthy();

    path = @"My.app";
    expect([Application appBundleOrIpaArchiveExistsAtPath:path]).to.beFalsy();

    NSString *directory = [[Resources shared] uniqueTmpDirectory];
    expect([Application appBundleOrIpaArchiveExistsAtPath:directory]).to.beFalsy();

    path = [directory stringByAppendingPathComponent:@"My.app"];
    NSData *data = [@"contents" dataUsingEncoding:NSUTF8StringEncoding];
    [[NSFileManager defaultManager] createFileAtPath:path
                                            contents:data
                                          attributes:nil];
    expect([Application appBundleOrIpaArchiveExistsAtPath:path]).to.beFalsy();
}

@end
