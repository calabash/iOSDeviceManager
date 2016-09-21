
#import <Foundation/Foundation.h>

@interface CodesignIdentity : NSObject <NSCopying>
+ (CodesignIdentity *) getUsableCodesignIdentityForAppBundle:(NSString *)appBundle deviceId:(NSString *)deviceId;
+ (NSArray<CodesignIdentity *> *)validIOSDeveloperIdentities;
+ (NSString *)codeSignIdentityFromEnvironment;

- (instancetype)initWithShasum:(NSString *)shasum
                          name:(NSString *)name;

- (BOOL)isIOSDeveloperIdentity;
- (id)copyWithZone:(NSZone *)zone;
- (NSString *)shasum;
- (NSString *)name;

@end
