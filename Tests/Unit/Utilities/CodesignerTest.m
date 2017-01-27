
#import "TestCase.h"
#import "Codesigner.h"

@interface Codesigner (TEST)

@property(copy) NSString *deviceUDID;

@end

@interface CodesignerTest : TestCase

@end

@implementation CodesignerTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

//TODO: Unit tests

@end
