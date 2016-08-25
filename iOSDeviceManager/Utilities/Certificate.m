
#import "Certificate.h"
#import "ShellRunner.h"

// Always always always use Apple's openssl binary.
static NSString *const kOpenSSLPath = @"/usr/bin/openssl";

// Always use Apple's shasum binary; results from others may vary.
static NSString *const kShasumPath = @"/usr/bin/shasum";

@interface Certificate ()

+ (BOOL)exportCertificate:(NSData *)data toFile:(NSString *)path;
+ (NSDictionary <NSString *, NSArray *> *)parseCertificateData:(NSData *)data
                                                        atPath:(NSString *)path;

@property(copy, readonly) NSString *subjectLine;
@property(copy, readonly) NSDictionary *info;
@property(copy, readonly) NSString *shasumLine;
@property(copy, readonly) NSString *shasum;

@end

@implementation Certificate

+ (Certificate *)certificateWithData:(NSData *)data {
    NSString *uuid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *name = [NSString stringWithFormat:@"%@.cert", uuid];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:name];

    NSDictionary *dictionary;
    dictionary = [Certificate parseCertificateData:data atPath:path];

    if (!dictionary) { return nil; }

    // "text" key will always be present and point to an array of strings.
    NSArray<NSString *> *lines = dictionary[@"text"];
    NSString *subjectLine = lines[0];

    if (![subjectLine containsString:@"subject"]) {
        NSLog(@"ERROR: Expected a subject line after exporting certificate with openssl");
        NSLog(@"ERROR: Found:\n    %@", subjectLine);
        return nil;
    }

    // "shasum" key will always be present and point to an array of strings.
    lines = dictionary[@"shasum"];
    NSString *shasumLine = lines[0];

    if (shasumLine.length == 0) {
        NSLog(@"ERROR: Expected a shasum after exporting certificate with openssl");
        return nil;
    }

    return [[Certificate alloc] initWithSubjectLine:subjectLine
                                         shasumLine:shasumLine];
}

+ (BOOL)exportCertificate:(NSData *)data toFile:(NSString *)path {
    NSError *error;
    if (![data writeToFile:path options:NSDataWritingAtomic error:&error]) {
        NSLog(@"ERROR: Could not export certificate data to file");
        NSLog(@"ERROR: %@", [error localizedDescription]);
        return NO;
    }
    return YES;
}

+ (NSDictionary <NSString *, NSArray *> *)parseCertificateData:(NSData *)data
                                                        atPath:(NSString *)path {
    if (![Certificate exportCertificate:data toFile:path]) {
        return nil;
    }

    NSArray<NSString *> *args;

    args = @[kOpenSSLPath, @"x509", @"-subject", @"-noout", @"-inform", @"der", @"-in", path];

    ShellResult *result = [ShellRunner xcrun:args timeout:20];

    if (!result.success) {
        NSLog(@"ERROR: Could not parse certificate at path:   \n%@", path);
        NSLog(@"ERROR: with command:\n    %@", result.command);
        if (result.didTimeOut) {
            NSLog(@"ERROR: command timed out after %@ seconds", @(result.elapsed));
        } else {
            NSLog(@"=== STDERR ===");
            NSLog(@"%@", result.stderr);
        }
        return nil;
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    dictionary[@"text"]  = result.stdoutLines ?: @[@""];

    args = @[kShasumPath, path];

    result = [ShellRunner xcrun:args timeout:10];

    if (!result.success) {
        NSLog(@"ERROR: Could not find the shasum of certificate at path:   \n%@", path);
        NSLog(@"ERROR: with command:\n    %@", result.command);
        if (result.didTimeOut) {
            NSLog(@"ERROR: command timed out after %@ seconds", @(result.elapsed));
        } else {
            NSLog(@"=== STDERR ===");
            NSLog(@"%@", result.stderr);
        }
        return nil;
    }

    dictionary[@"shasum"] = result.stdoutLines ?: @[@""];

    return dictionary;
}

@synthesize subjectLine = _subjectLine;
@synthesize shasumLine = _shasumLine;
@synthesize info = _info;
@synthesize shasum = _shasum;

- (instancetype)initWithSubjectLine:(NSString *)subjectLine
                         shasumLine:(NSString *)shasumLine {
    self = [super init];
    if (self) {
        _subjectLine = subjectLine;
        _shasumLine = shasumLine;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"#<Certificate: %@ : %@ : %@>",
                     [[self shasum] substringToIndex:5],
                     [self teamName], [self commonName]];
}

- (NSDictionary *)info {
    if (_info) { return _info; }

    NSMutableDictionary *hash = [NSMutableDictionary dictionary];
    NSArray *components = [self.subjectLine componentsSeparatedByString:@"/"];

    for (NSString *string in components) {
        if ([string containsString:@"="] && ![string containsString:@"subject"]) {
           NSArray *keyValue = [string componentsSeparatedByString:@"="];
           hash[keyValue[0]] = keyValue[1];
        }
    }

    _info = [NSDictionary dictionaryWithDictionary:hash];
    return hash;
}

- (id)objectForKeyedSubscript:(NSString *) key {
    return self.info[key] ?: nil;
}

// UID=QWAW7NSN85
- (NSString *)userID {
    return self[@"UID"];
}

// CN=iPhone Developer: Karl Krukow (YTTN6Y2QS9)
- (NSString *)commonName {
    return self[@"CN"];
}

// OU=FYD86LA7RE
- (NSString *)teamName {
    return self[@"OU"];
}

// O=Karl Krukow
- (NSString *)organization {
    return self[@"O"];
}

// C=US
- (NSString *)country {
    return self[@"C"];
}

- (NSString *)shasum {
    if (_shasum) { return _shasum; }

    // We can safely return nil here because shasum comparison is done with:
    //     [mySum isEqualToString:otherSum]
    // which will return NO if the LHS or the RHS is nil.
    if (!self.shasumLine || self.shasumLine.length == 0) {
        return nil;
    }

    NSArray *tokens = [self.shasumLine componentsSeparatedByString:@" "];
    NSString *first = tokens[0];

    _shasum = [first uppercaseString];
    return _shasum;
}

@end
