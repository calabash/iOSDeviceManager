
#import <Foundation/Foundation.h>

@interface CodesignIdentity : NSObject <NSCopying>
+ (CodesignIdentity *)identityForAppBundle:(NSString *)appBundle
                                  deviceId:(NSString *)deviceId;
+ (CodesignIdentity *)adHoc;
+ (NSArray<CodesignIdentity *> *)validIOSDeveloperIdentities;
+ (NSString *)codeSignIdentityFromEnvironment;

- (instancetype)initWithShasum:(NSString *)shasum
                          name:(NSString *)name;

- (BOOL)isIOSDeveloperIdentity;
- (id)copyWithZone:(NSZone *)zone;
- (NSString *)shasum;
- (NSString *)name;

@end
