
#import "TestCase.h"
#import "Certificate.h"
#import "ShellRunner.h"
#import "ShasumProvider.h"

@interface Certificate (TEST)

+ (BOOL)exportCertificate:(NSData *)data toFile:(NSString *)path;
+ (NSString *)commonNameFromCertificateData:(NSData *)data;
@end

@interface ShasumProvider (TEST)
+ (NSString *)sha1FromData:(NSData *)data;
@end

@interface CertificateTest : TestCase

@end

@implementation CertificateTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInit {
    NSString *commonName, *shasum;
    commonName = @"iPhone Developer: Karl Krukow (YTTN6Y2QS9)";
    shasum = @"316b74b2838787366d1e76d33f3e621e5c2fafb8";

    Certificate *cert = [[Certificate alloc] initWithCommonName:commonName
                                                         shasum:shasum];

    expect(cert.commonName).to.equal(@"iPhone Developer: Karl Krukow (YTTN6Y2QS9)");
    expect(cert.shasum).to.equal(@"316B74B2838787366D1E76D33F3E621E5C2FAFB8");
}

- (void)testExportCertificateToFileYES {
    NSData *data = [self.resources certificateFromCalabashWildcardPath];
    NSString *directory = [self.resources tmpDirectoryWithName:@"certs"];
    NSString *path = [directory stringByAppendingPathComponent:@"my.cert"];

    BOOL actual;

    actual = [Certificate exportCertificate:data toFile:path];
    expect(actual).to.equal(YES);
    expect([self fileExists:path]).to.equal(YES);
}

- (void)testDictionaryByParsingCertificate {
    NSData *data = [self.resources certificateFromCalabashWildcardPath];

    NSString *actual;
    actual = [Certificate commonNameFromCertificateData:data];

    expect([actual containsString:@"Karl Krukow"]).to.equal(YES);
}

- (void)testCertificateByParsingDataSuccess {
    NSData *data = [self.resources certificateFromCalabashWildcardPath];
    Certificate *actual;

    actual = [Certificate certificateWithData:data];
    expect(actual.commonName).to.equal(@"iPhone Developer: Karl Krukow (YTTN6Y2QS9)");
}

- (void)testCertificateByParsingDataCouldNotParse {
    NSData *data = [self.resources certificateFromCalabashWildcardPath];
    Certificate *actual;

    id MockCertificate = OCMClassMock([Certificate class]);
    OCMExpect([MockCertificate commonNameFromCertificateData:OCMOCK_ANY]).andReturn(nil);

    actual = [Certificate certificateWithData:data];
    expect(actual).to.equal(nil);

    OCMVerifyAll(MockCertificate);
}

- (void)testCertificateByParsingDataUnexpectedShasumOutput {
    NSData *data = [self.resources certificateFromCalabashWildcardPath];
    Certificate *actual;

    id MockShasumProvider = OCMClassMock([ShasumProvider class]);
    OCMExpect([MockShasumProvider sha1FromData:OCMOCK_ANY]).andReturn(@"");


    actual = [Certificate certificateWithData:data];
    expect(actual).to.equal(nil);

    OCMVerifyAll(MockShasumProvider);
}

@end

SpecBegin(Certificate)

context(@"properties", ^{
    __block Certificate *cert;
    __block NSString *commonName;

    before(^{
        commonName = @"iPhone Developer: Karl Krukow (YTTN6Y2QS9)";
        cert = [[Certificate alloc] initWithCommonName:commonName shasum:nil];
    });

    it(@"#commonName returns the correct name", ^{
        expect(cert.commonName).to.equal(@"iPhone Developer: Karl Krukow (YTTN6Y2QS9)");
    });
});

context(@"#shasum", ^{
    __block Certificate *cert;

    it(@"returns nil if there are no lines from the output", ^{
        cert = [[Certificate alloc] initWithCommonName:@"name"
                                                shasum:nil];
        expect(cert.shasum).to.equal(nil);
    });

    it(@"returns empty string if the first line of output is an empty string", ^{
        cert = [[Certificate alloc] initWithCommonName:@"name"
                                                shasum:@""];
        expect(cert.shasum).to.equal(@"");
    });
});

SpecEnd
