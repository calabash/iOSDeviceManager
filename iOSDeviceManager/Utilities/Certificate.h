#import <Foundation/Foundation.h>

// TODO: check to see if the certificate has expired or has been revoked
// $ openssl x509 -enddate -inform der -in Tests/Resources/cert-from-CalabashWildcardProfile.cert
// notAfter=Jan  6 10:41:35 2017 GMT
// Unfortunately, the date could be in any of a number of formats.
//
// See the following SO post for tips on SecSecurity (OpenSSL).  The Apple OpenSSL docs
// discourage the use of SecSecurity.
// http://stackoverflow.com/questions/8850524/seccertificateref-how-to-get-the-certificate-information
@interface Certificate : NSObject

+ (Certificate *)certificateWithData:(NSData *)data;

- (instancetype)initWithSubjectLine:(NSString *)subjectLine
                         shasumLine:(NSString *)shasumLine;
- (NSString *)userID;
- (NSString *)commonName;
- (NSString *)teamName;
- (NSString *)organization;
- (NSString *)country;
- (NSString *)shasum;

@end
