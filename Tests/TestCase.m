#import "TestCase.h"

@implementation TestCase

@synthesize resources = _resources;

- (Resources *)resources {
    return [Resources shared]; //it's a dispatch_once'd singleton
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
