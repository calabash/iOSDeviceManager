
#import "XCTestConfigurationProxy.h"
#import <FBControlCore/FBControlCore.h>
#import "ConsoleWriter.h"
#import <objc/runtime.h>

@implementation XCTestConfigurationProxy

- (XCTestConfigurationProxy *)initWithConfiguration:(id)configuration {
    self = [super init];
    if (self) {
        self.configuration = configuration;
    }
    return self;
}

+ (FBWeakFramework *)XCTestFramework {
    NSString *path = @"Platforms/MacOSX.platform/Developer/Library/Frameworks/XCTest.framework";
    return [FBWeakFramework xcodeFrameworkWithRelativePath:path];
}

+ (BOOL)loadXCTestFramework:(FBWeakFramework *)framework {
    id<FBControlCoreLogger> logger = FBControlCoreGlobalConfiguration.defaultLogger;
    NSError *error = nil;
    if (![FBWeakFrameworkLoader loadPrivateFrameworks:@[framework]
                                               logger:logger
                                                error:&error]) {
        ConsoleWriteErr(@"Could not load XCTest.framework");
        ConsoleWriteErr(@"%@", [error localizedDescription]);
        return NO;
    }
    return YES;
}

+ (XCTestConfigurationProxy *)configurationWithContentsOfFile:(NSString *)path {

    FBWeakFramework *xctest = [XCTestConfigurationProxy XCTestFramework];
    if (![XCTestConfigurationProxy loadXCTestFramework:xctest]) {
        return nil;
    }

    NSFileManager *manager = [NSFileManager defaultManager];

    if (![manager fileExistsAtPath:path]) {
        ConsoleWriteErr(@"File does not exist at path: %@", path);
        return nil;
    }

    id config = [XCTestConfigurationProxy XCTestConfigurationWithContentsOfFile:path];

    if (!config) {
        ConsoleWriteErr(@"Could not create an XCTestConfiguration instance by decoding:");
        ConsoleWriteErr(@"  %@", path);
        return nil;
    }

    if (![config isKindOfClass:NSClassFromString(@"XCTestConfiguration")]) {
        ConsoleWriteErr(@"Could not create an XCTestConfiguration instance by decoding:");
        ConsoleWriteErr(@"  %@", path);
        ConsoleWriteErr(@"Decoded object in an instance of %@", [config class]);
        ConsoleWriteErr(@"%@", config);
        return nil;
    }

    return [[XCTestConfigurationProxy alloc] initWithConfiguration:config];
}

+ (id)XCTestConfigurationWithContentsOfFile:(NSString *)path {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [NSKeyedUnarchiver unarchiveObjectWithFile:path];
#pragma clang diagnostic pop
}

- (NSString *)description {
    return [self.configuration description];
}

- (NSDictionary *) dictionaryWithPropertiesOfObject:(id)obj
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    unsigned count;
    objc_property_t *properties = class_copyPropertyList([obj class], &count);

    for (int i = 0; i < count; i++) {
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        if ([obj valueForKey:key] != nil){
            
            if ([[obj valueForKey:key] isKindOfClass:[NSData class]] ||
                [[obj valueForKey:key] isKindOfClass:[NSDate class]] ||
                [[obj valueForKey:key] isKindOfClass:[NSNumber class]] ||
                [[obj valueForKey:key] isKindOfClass:[NSString class]] ||
                [[obj valueForKey:key] isKindOfClass:[NSArray class]] ||
                [[obj valueForKey:key] isKindOfClass:[NSDictionary class]]){

                [dict setObject:[obj valueForKey:key] forKey:key];
            }
            else{
                NSString *str = [NSString stringWithFormat:@"%@", [obj valueForKey:key]];
                [dict setObject:str forKey:key];
            }

        }
    }

    free(properties);

    return [NSDictionary dictionaryWithDictionary:dict];
}

- (BOOL)writeToPlistFile:(NSString *)path overwrite:(BOOL)overwrite {

    NSError *error = nil;

    NSFileManager *manager = [NSFileManager defaultManager];

    if ([manager fileExistsAtPath:path]) {
        if (overwrite) {
            if (![manager removeItemAtPath:path
                                     error:&error]) {
                ConsoleWriteErr(@"Could not overwrite file at path");
                ConsoleWriteErr(@"  %@", path);
                ConsoleWriteErr(@"while trying to write XCTestConfiguration");
                ConsoleWriteErr(@"%@", [error localizedDescription]);
                return NO;
            }
        } else {
            ConsoleWriteErr(@"File already exists at path");
            ConsoleWriteErr(@"  %@", path);
            ConsoleWriteErr(@"while trying to write XCTestConfiguration");
            ConsoleWriteErr(@"Use the --overwrite flag or delete the existing file");
            return NO;
        }
    }

    NSDictionary* dict = [self dictionaryWithPropertiesOfObject:self.configuration];

    BOOL success = [dict writeToFile:path atomically:YES];

    
    return success;
}

@end

