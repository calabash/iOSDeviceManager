#import "CodesignResources.h"

@implementation CodesignResources

+ (NSString *)resourcesDirectory {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    return [[bundle resourcePath]stringByAppendingPathComponent:@"Resources"];
}

+ (NSString *)CalabashDylibPath {
    return [[CodesignResources resourcesDirectory] stringByAppendingPathComponent:@"calabash.dylib"];
}

+ (NSString *)TaskyIpaPath {
    return [[[CodesignResources resourcesDirectory]
             stringByAppendingPathComponent:@"arm"]
            stringByAppendingPathComponent:@"TaskyPro.ipa"];
}

+ (NSString *)TaskyAppBundleID {
    return @"com.xamarin.samples.taskyprotouch";
}

+ (NSString *)PermissionsAppBundleID {
    return @"sh.calaba.Permissions";
}

+ (NSString *)PermissionsIpaPath {
    return [[[CodesignResources resourcesDirectory]
             stringByAppendingPathComponent:@"arm"]
            stringByAppendingPathComponent:@"Permissions.ipa"];
}

+ (NSString *)CalabashCodesignPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *calabashCodesignDir = [[NSHomeDirectory()
                                      stringByAppendingPathComponent:@".calabash"]
                                     stringByAppendingPathComponent:@"calabash-codesign"];

    if (![fileManager fileExistsAtPath:calabashCodesignDir]) {
        @throw [NSException exceptionWithName:@"MissingDirectoryException"
                                       reason:@"calabash-codesign directory does not exist"
                                     userInfo:nil];
    }

    return calabashCodesignDir;
}

+ (NSString *)CalabashWildcardProfilePath {
    return [[[[CodesignResources CalabashCodesignPath]
              stringByAppendingPathComponent:@"apple"]
             stringByAppendingPathComponent:@"profiles"]
            stringByAppendingPathComponent:@"CalabashWildcard.mobileprovision"];
}

+ (NSString *)CalabashPermissionsProfilePath {
    return [[[[CodesignResources CalabashCodesignPath]
              stringByAppendingPathComponent:@"apple"]
             stringByAppendingPathComponent:@"profiles"]
            stringByAppendingPathComponent:@"PermissionsDevelopment.mobileprovision"];
}

@end
