#import <Foundation/Foundation.h>
#import "TestCase.h"
#import "MachClock.h"

@interface MachClockTests : TestCase

@end

@implementation MachClockTests

- (void) testIntervalIsAccurate {

    NSTimeInterval sleepInterval = .05;
    NSTimeInterval startTime = [[MachClock sharedClock] absoluteTime];

    [NSThread sleepForTimeInterval:sleepInterval];

    NSTimeInterval endTime = [[MachClock sharedClock] absoluteTime];

    NSTimeInterval interval = endTime - startTime;

    // The interval should be > the slept amount, but not by more than 1/100 s
    // there is some overhead that is making the sleep time usually around .0535 seconds
    expect(interval).to.beGreaterThan(sleepInterval);
    expect(interval).to.beLessThan(sleepInterval + .01);
}

@end
