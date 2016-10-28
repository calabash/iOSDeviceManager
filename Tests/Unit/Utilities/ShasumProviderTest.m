#import <Foundation/Foundation.h>
#import "ShasumProvider.h"
#import "TestCase.h"

@interface ShasumProviderTest : TestCase

@end

@implementation ShasumProviderTest

- (void)testSha1FromData {
    NSData *data = [self.resources certificateFromCalabashWildcardPath];

    NSString *expectedSha = @"316b74b2838787366d1e76d33f3e621e5c2fafb8";
    NSString *actualSha = [ShasumProvider sha1FromData:data];

    expect(actualSha).to.equal(expectedSha);
}

@end
