
#import "ShellRunner.h"
#import "Codesigner.h"

@implementation Codesigner

- (BOOL)signBundleAtPath:(NSString *)bundlePath error:(NSError * _Nullable __autoreleasing * _Nullable)e {
    NSAssert(self.codesignIdentity != nil, @"Can not have a codesign command without an identity name");
    NSArray<NSString *> *ents = [ShellRunner shell:@"/usr/bin/xcrun"
                                              args:@[@"codesign",
                                                     @"-d",
                                                     @"--entitlements",
                                                     @":-",
                                                     bundlePath]];
    if (ents.count > 1 /* a valid ents plist should have more than one line */) {
        NSString *entsPlist = [ents componentsJoinedByString:@"\n"];
        NSString *fileName = [NSString stringWithFormat:@"%@_%@",
                              [[NSProcessInfo processInfo] globallyUniqueString], @"entitlements.plist"];
        NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
        
        if (![entsPlist writeToFile:filePath
                         atomically:YES
                           encoding:NSUTF8StringEncoding
                              error:e] || *e) {
            NSLog(@"Unable to create entitlements file: %@", *e);
            exit(1);
        }
        if ([ShellRunner verbose]) {
            NSLog(@"Entitlements tmpfile %@:\n%@", filePath, entsPlist);
        }
        
        return [ShellRunner shell:@"/usr/bin/xcrun"
                             args:@[@"codesign",
                                    @"-s",
                                    self.codesignIdentity,
                                    @"-f",
                                    @"--entitlements",
                                    filePath,
                                    @"--deep",
                                    bundlePath]] != nil;
    } else {
        return [ShellRunner shell:@"/usr/bin/xcrun"
                             args:@[@"codesign",
                                    @"-s",
                                    self.codesignIdentity,
                                    @"-f",
                                    @"--deep",
                                    bundlePath]] != nil;
    }
}

/*
    FBSimulatorControl/FBCodesignCommand.m
    - (nullable NSString *)cdHashForBundleAtPath:(NSString *)bundlePath error:(NSError **)error
 */
- (nullable NSString *)cdHashForBundleAtPath:(NSString *)bundlePath error:(NSError **)error
{
    id<FBTask> task = [[FBTaskExecutor.sharedInstance
                        taskWithLaunchPath:@"/usr/bin/codesign" arguments:@[@"-dvvvv", bundlePath]]
                       startSynchronouslyWithTimeout:FBControlCoreGlobalConfiguration.fastTimeout];
    if (task.error) {
        return [[[XCTestBootstrapError
                  describe:@"Could not execute codesign"]
                 causedBy:task.error]
                fail:error];
    }
    NSArray *lines = [[task stdOut] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *cdHash;
    for (NSString *line in lines) {
        if ([line containsString:@"CDHash"]) {
            cdHash = line;
        }
    }
    
    if (!cdHash) {
        return [[[XCTestBootstrapError
                  describeFormat:@"Could not find 'CDHash' in output: %@", task.stdOut]
                 causedBy:task.error]
                fail:error];
    }
    return cdHash;
}

@end
