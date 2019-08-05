
#import "XcodeUtils.h"
#import "ShellResult.h"
#import "ShellRunner.h"

@implementation XcodeUtils
static NSUInteger _versionMajor = 0;
static NSUInteger _versionMinor = 0;

+ (NSUInteger) versionMajor {
    if (!_versionMajor) {
        [self getXcodeVersionTo:&_versionMajor and:&_versionMinor];
    }
    return _versionMajor;
}

+ (NSUInteger) versionMinor {
    if (!_versionMinor) {
        [self getXcodeVersionTo:&_versionMajor and:&_versionMinor];
    }
    return _versionMinor;

}

+ (void) getXcodeVersionTo:(NSUInteger *)major and:(NSUInteger*) minor{

    ShellResult *shellResult = [ShellRunner xcrun:@[@"xcodebuild", @"-version"]
                                          timeout:10];

    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"Xcode\\s+(\\d+)\\.(\\d+)"
                                  options:0 error:nil];

    NSString *output = shellResult.stdoutStr;
    NSArray *matches = [regex
                        matchesInString:output
                        options:0 range:NSMakeRange(0, [output length])];

    NSString *j = [output
                   substringWithRange:[(NSTextCheckingResult*)matches[0]
                                       rangeAtIndex:1]];
    NSString *i = [output
                   substringWithRange:[(NSTextCheckingResult*)matches[0]
                                       rangeAtIndex:2]];
    *major = j.intValue;
    *minor = i.intValue;
}
@end
