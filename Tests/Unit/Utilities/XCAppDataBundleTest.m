
#import "TestCase.h"
#import "XCAppDataBundle.h"

@interface XCAppDataBundle (TEST)

+ (BOOL)hasCorrectExtension:(NSString *)path;
+ (BOOL)isDirectory:(NSString *)path;
+ (BOOL)hasCorrectStructure:(NSString *)path;
+ (BOOL)hasAppDataDirectory:(NSString *)path;
+ (BOOL)hasDocumentsDirectory:(NSString *)path;
+ (BOOL)hasLibraryDirectory:(NSString *)path;
+ (BOOL)hasLibraryPreferencesDirectory:(NSString *)path;
+ (BOOL)hasTmpDirectory:(NSString *)path;
+ (BOOL)hasSubDirectory:(NSString *)path
              directory:(NSString *)name;

@end

@interface XCAppDataBundleTest : TestCase

@end

@implementation XCAppDataBundleTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testHasCorrectExtension {
    NSString *path;

    path = @"/path/to/my/app.xcappdata";
    expect([XCAppDataBundle hasCorrectExtension:path]).to.equal(YES);

    path = @"/path/to/my/app.anything-else";
    expect([XCAppDataBundle hasCorrectExtension:path]).to.equal(NO);
}

- (BOOL)createFileAtPath:(NSString *)path
                    file:(NSString *)name {
    NSString *filePath = [path stringByAppendingPathComponent:name];
    NSData *data = [@"contents" dataUsingEncoding:NSUTF8StringEncoding];
    return [[NSFileManager defaultManager] createFileAtPath:filePath
                                                   contents:data
                                                 attributes:nil];
}

- (BOOL)createSubDirectoryAtPath:(NSString *)path
                       directory:(NSString *)name {
    return [self createSubDirectoriesAtPath:path
                                directories:@[name]];
}

- (BOOL)createSubDirectoriesAtPath:(NSString *)path
                       directories:(NSArray<NSString *> *)components {

    NSString *finalPath = path;
    for (NSString *component in components) {
        finalPath = [finalPath stringByAppendingPathComponent:component];
    }

    return [[NSFileManager defaultManager] createDirectoryAtPath:finalPath
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:nil];
}

- (void)testIsDirectory {
    NSString *path;

    path = @"path/to/my/app.xcappdata";
    expect([XCAppDataBundle isDirectory:path]).to.beFalsy();

    path = [[Resources shared] uniqueTmpDirectory];
    expect([XCAppDataBundle isDirectory:path]).to.beTruthy();

    expect([self createFileAtPath:path file:@"file.txt"]).to.beTruthy();
    path = [path stringByAppendingPathComponent:@"file.txt"];
    expect([XCAppDataBundle isDirectory:path]).to.beFalsy();
}


- (void)testHasSubDirectory {
    NSString *path = [[Resources shared] tmpDirectoryWithName:@"My.xcappdata"];
    expect([XCAppDataBundle hasSubDirectory:path directory:@"AppData"]).to.beFalsy();
}

- (void)testHasAppDataDirectory {
    NSString *path = [[Resources shared] tmpDirectoryWithName:@"My.xcappdata"];
    expect([XCAppDataBundle hasAppDataDirectory:path]).to.equal(NO);

    expect([self createFileAtPath:path file:@"AppData"]).to.beTruthy();
    expect([XCAppDataBundle hasAppDataDirectory:path]).to.equal(NO);

    path = [[Resources shared] tmpDirectoryWithName:@"Other.xcappdata"];
    expect([self createSubDirectoryAtPath:path directory:@"AppData"]).to.beTruthy();
    expect([XCAppDataBundle hasAppDataDirectory:path]).to.equal(YES);
}

- (void)testHasDocumentsDirectory {
    NSString *path = [[Resources shared] tmpDirectoryWithName:@"My.xcappdata"];
    expect([self createSubDirectoryAtPath:path directory:@"AppData"]).to.beTruthy();
    expect([XCAppDataBundle hasDocumentsDirectory:path]).to.equal(NO);

    expect([self createFileAtPath:[path stringByAppendingPathComponent:@"AppData"]
                             file:@"Documents"]).to.beTruthy();
    expect([XCAppDataBundle hasDocumentsDirectory:path]).to.beFalsy();

    path = [[Resources shared] tmpDirectoryWithName:@"Other.xcappdata"];
    expect([self createSubDirectoriesAtPath:path
                                directories:@[@"AppData", @"Documents"]]).to.beTruthy();
    expect([XCAppDataBundle hasDocumentsDirectory:path]).to.equal(YES);
}

- (void)testHasTmpDirectory {
    NSString *path = [[Resources shared] tmpDirectoryWithName:@"My.xcappdata"];
    expect([self createSubDirectoryAtPath:path directory:@"AppData"]).to.beTruthy();
    expect([XCAppDataBundle hasTmpDirectory:path]).to.equal(NO);

    expect([self createFileAtPath:[path stringByAppendingPathComponent:@"AppData"]
                             file:@"tmp"]).to.beTruthy();
    expect([XCAppDataBundle hasTmpDirectory:path]).to.beFalsy();

    path = [[Resources shared] tmpDirectoryWithName:@"Other.xcappdata"];
    expect([self createSubDirectoriesAtPath:path
                                directories:@[@"AppData", @"tmp"]]).to.beTruthy();
    expect([XCAppDataBundle hasTmpDirectory:path]).to.equal(YES);
}

- (void)testHasLibraryDirectory {
    NSString *path = [[Resources shared] tmpDirectoryWithName:@"My.xcappdata"];
    expect([self createSubDirectoryAtPath:path directory:@"AppData"]).to.beTruthy();
    expect([XCAppDataBundle hasLibraryDirectory:path]).to.equal(NO);

    expect([self createFileAtPath:[path stringByAppendingPathComponent:@"AppData"]
                             file:@"Library"]).to.beTruthy();
    expect([XCAppDataBundle hasLibraryDirectory:path]).to.beFalsy();

    path = [[Resources shared] tmpDirectoryWithName:@"Other.xcappdata"];
    expect([self createSubDirectoriesAtPath:path
                                directories:@[@"AppData", @"Library"]]).to.beTruthy();
    expect([XCAppDataBundle hasLibraryDirectory:path]).to.equal(YES);
}

- (void)testHasLibraryPreferencesDirectory {
    NSString *path = [[Resources shared] tmpDirectoryWithName:@"My.xcappdata"];
    expect([self createSubDirectoriesAtPath:path
                                directories:@[@"AppData", @"Preferences"]]).to.beTruthy();
    expect([XCAppDataBundle hasLibraryPreferencesDirectory:path]).to.equal(NO);

    NSString *subDir = [[path stringByAppendingPathComponent:@"AppData"]
                        stringByAppendingPathComponent:@"Preferences"];
    expect([self createFileAtPath:subDir file:@"Preferences"]).to.beTruthy();
    expect([XCAppDataBundle hasLibraryDirectory:path]).to.beFalsy();

    path = [[Resources shared] tmpDirectoryWithName:@"Other.xcappdata"];
    NSArray *dirs = @[@"AppData", @"Library", @"Preferences"];
    expect([self createSubDirectoriesAtPath:path directories:dirs]).to.beTruthy();
    expect([XCAppDataBundle hasLibraryDirectory:path]).to.equal(YES);
}

- (void)testIsValid {
    NSString *path = [[Resources shared] tmpDirectoryWithName:@"My"];
    expect([XCAppDataBundle isValid:path]).to.beFalsy();

    path = [[Resources shared] tmpDirectoryWithName:@"My.xcappdata"];
    expect([XCAppDataBundle isValid:path]).to.beFalsy();

    expect([self createSubDirectoryAtPath:path directory:@"AppData"]).to.beTruthy();
    expect([XCAppDataBundle isValid:path]).to.beFalsy();

    expect([self createSubDirectoriesAtPath:path
                                directories:@[@"AppData", @"Documents"]]).to.beTruthy();
    expect([XCAppDataBundle isValid:path]).to.beFalsy();

    expect([self createSubDirectoriesAtPath:path
                                directories:@[@"AppData", @"tmp"]]).to.beTruthy();
    expect([XCAppDataBundle isValid:path]).to.beFalsy();

    expect([self createSubDirectoriesAtPath:path
                                directories:@[@"AppData", @"Library"]]).to.beTruthy();
    expect([XCAppDataBundle isValid:path]).to.beFalsy();

    expect([self createSubDirectoriesAtPath:path
                                directories:@[@"AppData",
                                              @"Library",
                                              @"Preferences"]]).to.beTruthy();
    expect([XCAppDataBundle isValid:path]).to.beTruthy();
}

- (void)testGenerateSkeleton {

    NSString *path = [[Resources shared] uniqueTmpDirectory];
    NSString *name = @"My.xcappdata";

    // happy path
    expect([XCAppDataBundle generateBundleSkeleton:path
                                              name:name
                                         overwrite:NO]).to.beTruthy();

    // overwrite
    expect([XCAppDataBundle generateBundleSkeleton:path
                                              name:name
                                         overwrite:YES]).to.beTruthy();

    // creates missing subdirectories
    path = [[Resources shared] uniqueTmpDirectory];
    path = [path stringByAppendingPathComponent:@"DoesNotExist"];
    expect([XCAppDataBundle generateBundleSkeleton:path
                                              name:name
                                         overwrite:NO]).to.beTruthy();
}

@end
