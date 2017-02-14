#import <XCTest/XCTest.h>
#import "TestUtils.h"

@interface TestCase : XCTestCase

@property(strong, readonly) Resources *resources;

- (BOOL)fileExists:(NSString *)path;

@end
