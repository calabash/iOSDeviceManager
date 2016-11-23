#include <mach/mach.h>
#include <mach/mach_time.h>
#include "MachClock.h"

// http://stackoverflow.com/questions/889380/how-can-i-get-a-precise-time-for-example-in-milliseconds-in-objective-c

@interface MachClock()

- (NSTimeInterval)machAbsoluteToTimeInterval:(uint64_t)machAbsolute;

@end

@implementation MachClock

mach_timebase_info_data_t _clock_timebase;

+ (instancetype)sharedClock
{
    static MachClock *clock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clock = [MachClock new];
    });
    return clock;
}

- (id)init
{
    if(!(self = [super init]))
        return nil;
    mach_timebase_info(&_clock_timebase);
    return self;
}

- (NSTimeInterval)machAbsoluteToTimeInterval:(uint64_t)machAbsolute
{
    uint64_t nanos = (machAbsolute * _clock_timebase.numer) / _clock_timebase.denom;

    return nanos/1.0e9;
}

- (NSTimeInterval)absoluteTime
{
    uint64_t machtime = mach_absolute_time();
    return [self machAbsoluteToTimeInterval:machtime];
}

@end
