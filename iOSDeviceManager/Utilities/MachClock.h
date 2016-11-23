#include <Foundation/Foundation.h>

@interface MachClock : NSObject

+ (instancetype)sharedClock;
- (NSTimeInterval)absoluteTime;

@end
