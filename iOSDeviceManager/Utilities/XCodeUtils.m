//
//  XCodeUtils.m
//  iOSDeviceManager
//
//  Created by Sergey Dolin on 10/10/2018.
//  Copyright © 2018 Microsoft. All rights reserved.
//

#import "XCodeUtils.h"
#import "ShellResult.h"
#import "ShellRunner.h"

@implementation XCodeUtils
static int _versionMajor=0;
static int _versionMinor=0;

+ (int) versionMajor {
    if (!_versionMajor) {
        [self getXcodeVersionTo:&_versionMajor and:&_versionMinor];
    }
    return _versionMajor;
}

+ (int) versionMinor {
    if (!_versionMinor) {
        [self getXcodeVersionTo:&_versionMajor and:&_versionMinor];
    }
    return _versionMinor;

}

+ (void) getXcodeVersionTo:(int *)major and:(int*) minor{

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
