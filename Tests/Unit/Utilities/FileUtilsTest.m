#import <Foundation/Foundation.h>
#import "FileUtils.h"
#import "TestCase.h"


@interface FileUtilsTest : TestCase

@end

@implementation FileUtilsTest

- (void)testExpandPath {
    NSString *path, *expected, *actual;
    NSString *currentDirectory = [[NSFileManager defaultManager] currentDirectoryPath];

    path = @"~/path/relative/to/home";
    expected = [NSHomeDirectory() stringByAppendingPathComponent:@"path/relative/to/home"];
    actual = [FileUtils expandPath:path];
    expect(actual).to.equal(expected);

    path = @"/path/with/../embedded/relative/component";
    expected = @"/path/embedded/relative/component";
    actual = [FileUtils expandPath:path];
    expect(actual).to.equal(expected);

    path = @"/path/with/./embedded/relative/component";
    expected = @"/path/with/embedded/relative/component";
    actual = [FileUtils expandPath:path];
    expect(actual).to.equal(expected);

    path = @"/path/with///unnecessary/path/separator";
    expected = @"/path/with/unnecessary/path/separator";
    actual = [FileUtils expandPath:path];
    expect(actual).to.equal(expected);

    path = @"//path/with/unnecessary/path/separator";
    expected = @"/path/with/unnecessary/path/separator";
    actual = [FileUtils expandPath:path];
    expect(actual).to.equal(expected);

    path = @"./path/with/leading/dot";
    expected = [currentDirectory stringByAppendingPathComponent:@"path/with/leading/dot"];
    actual = [FileUtils expandPath:path];
    expect(actual).to.equal(expected);

    path = @"path/relative/to/current/directory";
    expected = [currentDirectory stringByAppendingPathComponent:@"path/relative/to/current/directory"];
    actual = [FileUtils expandPath:path];
    expect(actual).to.equal(expected);

    path = @"../path/with/leading/relative/component";
    NSString *upOneDirectory = [currentDirectory stringByDeletingLastPathComponent];
    expected = [upOneDirectory stringByAppendingPathComponent:@"path/with/leading/relative/component"];
    actual = [FileUtils expandPath:path];
    expect(actual).to.equal(expected);
}

@end
