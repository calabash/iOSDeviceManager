#import "ShasumProvider.h"
#import "Certificate.h"
#import "ShellRunner.h"
#import "ShellResult.h"
#import "ConsoleWriter.h"

@interface Certificate ()

+ (BOOL)exportCertificate:(NSData *)data toFile:(NSString *)path;
+ (NSString *)commonNameFromCertificateData:(NSData *)data;

@end

@implementation Certificate

+ (Certificate *)certificateWithData:(NSData *)data {
    NSString *commonName = [Certificate commonNameFromCertificateData:data];

    if (!commonName) { return nil; }

    NSString *shasum = [ShasumProvider sha1FromData:data];

    if (shasum.length == 0) {
        ConsoleWriteErr(@"Expected a shasum after exporting certificate with openssl");
        return nil;
    }

    return [[Certificate alloc] initWithCommonName:commonName shasum:shasum];
}

+ (BOOL)exportCertificate:(NSData *)data toFile:(NSString *)path {
    NSError *error;
    if (![data writeToFile:path options:NSDataWritingAtomic error:&error]) {
        ConsoleWriteErr(@"Could not export certificate data to file");
        ConsoleWriteErr(@"%@", [error localizedDescription]);
        return NO;
    }
    return YES;
}

+ (NSString *)commonNameFromCertificateData:(NSData *)data {

    CFDataRef dataRef = CFDataCreate(NULL, [data bytes], [data length]);
    if (!dataRef) {
        ConsoleWriteErr(@"Could not extract the common name for the certificate");
        return nil;
    }

    SecCertificateRef certRef;
    certRef = SecCertificateCreateWithData(NULL, dataRef);

    CFStringRef stringRef;
    OSStatus status;
    status = SecCertificateCopyCommonName(certRef, &stringRef);

    if (status != errSecSuccess) {
        ConsoleWriteErr(@"Unsuccessful getting common name from certificate");
        ConsoleWriteErr(@"Result code: %@", status);
    }

    NSString *name = (__bridge NSString *)stringRef;
    CFRelease(certRef);
    CFRelease(stringRef);

    return name;
}

@synthesize commonName = _commonName;
@synthesize shasum = _shasum;

- (instancetype)initWithCommonName:(NSString *)commonName
                            shasum:(NSString *)shasum {
    self = [super init];
    if (self) {
        _commonName = commonName;
        _shasum = [shasum uppercaseString];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"#<Certificate: %@ : %@>",
            [[self shasum] substringToIndex:5], [self commonName]];
}

@end
