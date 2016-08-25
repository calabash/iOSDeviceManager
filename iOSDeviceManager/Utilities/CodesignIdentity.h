
#import <Foundation/Foundation.h>

@interface CodesignIdentity : NSObject <NSCopying>

+ (NSArray<CodesignIdentity *> *)validIOSDeveloperIdentities;
+ (NSString *)codeSignIdentityFromEnvironment;

- (instancetype)initWithShasum:(NSString *)shasum
                          name:(NSString *)name;

- (BOOL)isIOSDeveloperIdentity;
- (id)copyWithZone:(NSZone *)zone;
- (NSString *)shasum;
- (NSString *)name;

@end
