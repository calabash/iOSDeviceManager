
#import <Foundation/Foundation.h>


@interface Entitlements : NSObject

+ (Entitlements *)entitlementsWithBundlePath:(NSString *)bundlePath;
+ (Entitlements *)entitlementsWithDictionary:(NSDictionary *)dictionary;

+ (NSInteger)rankByComparingProfileEntitlements:(Entitlements *)profileEntitlements
                                appEntitlements:(Entitlements *)appEntitlements;

- (BOOL)writeToFile:(NSString *)path;
- (id)objectForKeyedSubscript:(NSString *)key;

// Required during the code signing to generate a new .xcent file.
- (Entitlements *)entitlementsByReplacingApplicationIdentifier:(NSString *)applicationIdentifier;

@end