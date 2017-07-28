
#import <Foundation/Foundation.h>
#import "Application.h"

@class MobileProfile;

@interface Entitlements : NSObject

+ (Entitlements *)entitlementsWithBundlePath:(NSString *)bundlePath;
+ (Entitlements *)entitlementsWithDictionary:(NSDictionary *)dictionary;
+ (NSDictionary *)dictionaryOfEntitlementsWithBundlePath:(NSString *)bundlePath;

+ (void)compareEntitlementsWithProfile:(MobileProfile *)profile app:(Application *)app;
+ (NSInteger)rankByComparingProfileEntitlements:(Entitlements *)profileEntitlements
                                appEntitlements:(Entitlements *)appEntitlements;

- (NSInteger)count;
- (NSString *)applicationIdentifier;
- (NSString *)applicationIdentifierWithoutPrefix;
- (BOOL)writeToFile:(NSString *)path;
- (id)objectForKeyedSubscript:(NSString *)key;

// Required during the code signing to generate a new .xcent file.
- (Entitlements *)entitlementsByReplacingApplicationIdentifier:(NSString *)applicationIdentifier;

@end
