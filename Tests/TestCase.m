#import "TestCase.h"

@implementation TestCase

@synthesize resources = _resources;

- (Resources *)resources {
    if (_resources) { return _resources; }

    _resources = [Resources shared];
    return _resources;
}

- (void)setUp {
    [self.resources setDeveloperDirectory];
    [Simctl shared];
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (BOOL)fileExists:(NSString *)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

@end
