
#import "TestCase.h"
#import "Certificate.h"
#import "ShellRunner.h"
#import "ShasumProvider.h"

@interface Certificate (TEST)

+ (BOOL)exportCertificate:(NSData *)data toFile:(NSString *)path;
+ (NSString *)subjectForCertificateData:(NSData *)data;
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
    NSString *subjectLine, *shasumLine;
    subjectLine = @"subject= /UID=QWAW7NSN85/CN=iPhone Developer: Karl Krukow (YTTN6Y2QS9)/"
    "OU=FYD86LA7RE/O=Karl Krukow/C=US";
    shasumLine = @"316b74b2838787366d1e76d33f3e621e5c2fafb8 "
    "Tests/Resources/cert-from-CalabashWildcardProfile.cert";

    Certificate *cert = [[Certificate alloc] initWithSubjectLine:subjectLine
                                                      shasumLine:shasumLine];

    expect(cert.userID).to.equal(@"QWAW7NSN85");
    expect(cert.commonName).to.equal(@"iPhone Developer: Karl Krukow (YTTN6Y2QS9)");
    expect(cert.teamName).to.equal(@"FYD86LA7RE");
    expect(cert.organization).to.equal(@"Karl Krukow");
    expect(cert.country).to.equal(@"US");

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
    NSString *path = [self.resources pathToCalabashWildcardPathCertificate];
    NSData *data = [self.resources certificateFromCalabashWildcardPath];

    NSString *actual;
    actual = [Certificate subjectForCertificateData:data];

    expect([actual containsString:@"subject"]).to.equal(YES);
}

- (void)testDictionaryByParsingCertificateTimedOut {
    NSString *path = [self.resources pathToCalabashWildcardPathCertificate];
    NSData *data = [self.resources certificateFromCalabashWildcardPath];

    id MockShellRunner = OCMClassMock([ShellRunner class]);
    ShellResult *result = [[Resources shared] timedOutResult];
    OCMExpect([MockShellRunner xcrun:OCMOCK_ANY timeout:20]).andReturn(result);

    NSString *actual;
    actual = [Certificate subjectForCertificateData:data];

    expect(actual).to.equal(nil);
}

- (void)testStringByParsingCertificateError {
    NSString *path = [self.resources pathToCalabashWildcardPathCertificate];
    NSData *data = [self.resources certificateFromCalabashWildcardPath];

    id MockShellRunner = OCMClassMock([ShellRunner class]);
    ShellResult *result = [[Resources shared] failedResult];
    OCMExpect([MockShellRunner xcrun:OCMOCK_ANY timeout:20]).andReturn(result);

    NSString *actual;
    actual = [Certificate subjectForCertificateData:data];

    expect(actual).to.equal(nil);

    OCMVerifyAll(MockShellRunner);
}

- (void)testCertificateByParsingDataSuccess {
    NSData *data = [self.resources certificateFromCalabashWildcardPath];
    Certificate *actual;

    actual = [Certificate certificateWithData:data];
    expect(actual.userID).to.equal(@"QWAW7NSN85");
    expect(actual.commonName).to.equal(@"iPhone Developer: Karl Krukow (YTTN6Y2QS9)");
    expect(actual.teamName).to.equal(@"FYD86LA7RE");
    expect(actual.organization).to.equal(@"Karl Krukow");
    expect(actual.country).to.equal(@"US");
}

- (void)testCertificateByParsingDataCouldNotParse {
    NSData *data = [self.resources certificateFromCalabashWildcardPath];
    Certificate *actual;

    id MockCertificate = OCMClassMock([Certificate class]);
    OCMExpect([MockCertificate subjectForCertificateData:OCMOCK_ANY]).andReturn(nil);

    actual = [Certificate certificateWithData:data];
    expect(actual).to.equal(nil);

    OCMVerifyAll(MockCertificate);
}

- (void)testCertificateByParsingDataUnexpectedSubjectOutput {
    NSData *data = [self.resources certificateFromCalabashWildcardPath];
    Certificate *actual;

    NSString *line = @"Unexpected first line";

    id MockCertificate = OCMClassMock([Certificate class]);
    OCMExpect([MockCertificate subjectForCertificateData:OCMOCK_ANY])
    .andReturn(line);

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
    __block NSString *subject;

    before(^{
        subject = @"subject= /UID=QWAW7NSN85/CN=iPhone Developer: Karl Krukow (YTTN6Y2QS9)/"
        "OU=FYD86LA7RE/O=Karl Krukow/C=US";
        cert = [[Certificate alloc] initWithSubjectLine:subject
                                             shasumLine:nil];
    });

    it(@"#userID returns the UID", ^{
        expect(cert.userID).to.equal(@"QWAW7NSN85");
    });

    it(@"#commonName returns the CN", ^{
        expect(cert.commonName).to.equal(@"iPhone Developer: Karl Krukow (YTTN6Y2QS9)");
    });

    it(@"#teamName returns the OU", ^{
        expect(cert.teamName).to.equal(@"FYD86LA7RE");
    });

    it(@"#organization returns the O", ^{
        expect(cert.organization).to.equal(@"Karl Krukow");
    });

    it(@"#country returns the C", ^{
        expect(cert.country).to.equal(@"US");
    });
});

context(@"#shasum", ^{
    __block Certificate *cert;

    it(@"returns nil if there are no lines from the output", ^{
        cert = [[Certificate alloc] initWithSubjectLine:@"subject/"
                                             shasumLine:nil];
        expect(cert.shasum).to.equal(nil);
    });

    it(@"returns nil if the first line of output is an empty string", ^{
        cert = [[Certificate alloc] initWithSubjectLine:@"subject/"
                                             shasumLine:@""];
        expect(cert.shasum).to.equal(nil);
    });

    it(@"returns the shasum in all caps from the first line of output", ^{
        cert = [[Certificate alloc] initWithSubjectLine:@"subject/"
                                             shasumLine:@"abcde path/to/cert"];
        expect(cert.shasum).to.equal(@"ABCDE");
    });
});
SpecEnd

