#import "TestCase.h"
#import "ShellResult.h"

@interface ShellResultTest : TestCase

@end

@implementation ShellResultTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}


- (void)testShellResultInitSuccess {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/echo"];
    [task setArguments:@[@"Hello"]];

    NSPipe *outPipe = [NSPipe pipe];
    [task setStandardOutput:outPipe];

    NSPipe *errPipe = [NSPipe pipe];
    [task setStandardError:errPipe];

    [task launch];
    [task waitUntilExit];

    ShellResult *result = [ShellResult withTask:task elapsed:1.0 didTimeOut:NO];

    expect(result.command).to.equal(@"/bin/echo Hello");
    expect(result.didTimeOut).to.equal(NO);
    expect(result.exitStatus).to.equal(0);
    expect(result.success).to.equal(YES);
    expect(result.elapsed).to.equal(1.0);
    expect(result.stderrStr).to.equal(@"");
    expect(result.stdoutStr).to.equal(@"Hello\n");
    expect(result.stdoutLines).to.equal(@[@"Hello", @""]);
}

- (void)testShellResultInitFailure {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/uname"];
    [task setArguments:@[@"-q"]];

    NSPipe *outPipe = [NSPipe pipe];
    [task setStandardOutput:outPipe];

    NSPipe *errPipe = [NSPipe pipe];
    [task setStandardError:errPipe];

    [task launch];
    [task waitUntilExit];

    ShellResult *result = [ShellResult withTask:task elapsed:1.0 didTimeOut:NO];

    expect(result.command).to.equal(@"/usr/bin/uname -q");
    expect(result.didTimeOut).to.equal(NO);
    expect(result.success).to.equal(NO);
    expect(result.elapsed).to.equal(1.0);
    expect(result.stderrStr).to.equal(@"/usr/bin/uname: illegal option -- q\n"
                                      "usage: uname [-amnprsv]\n");
    expect(result.stdoutStr).to.equal(@"");
    expect(result.stdoutLines).to.equal(@[@""]);
}

- (void)testInitShellResultTimedOut {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sleep"];
    [task setArguments:@[@"1.0"]];

    NSPipe *outPipe = [NSPipe pipe];
    [task setStandardOutput:outPipe];

    NSPipe *errPipe = [NSPipe pipe];
    [task setStandardError:errPipe];

    NSDate *endDate = [[NSDate date] dateByAddingTimeInterval:0.05];
    NSDate *startDate = [NSDate date];

    [task launch];

    while ([task isRunning]) {
        if ([endDate earlierDate:[NSDate date]] == endDate) {
            [task terminate];
        }
    }
    NSTimeInterval elapsed = [startDate timeIntervalSinceNow];
    DDLogVerbose(@"elapsed: %@", @(-1.0 * elapsed));

    ShellResult *result = [ShellResult withTask:task elapsed:1.0 didTimeOut:YES];

    expect(result.command).to.equal(@"/bin/sleep 1.0");
    expect(result.didTimeOut).to.equal(YES);
    expect(result.success).to.equal(NO);
    expect(result.elapsed).to.equal(1.0);
    expect(result.stderrStr).to.equal(@"");
    expect(result.stdoutStr).to.equal(@"");
    expect(result.stdoutLines).to.equal(@[@""]);
}

@end
