#import "LPTTYLogFormatter.h"
#import <libkern/OSAtomic.h>

static NSString *const CalLogFormatterDateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
static NSString *const CalLogFormatterDateFormatterKey = @"sh.calaba.CalSSO-CalLogFormatter-NSDateFormatter";
@interface LPTTYLogFormatter () {
  int32_t atomicLoggerCount;
  NSDateFormatter *threadUnsafeDateFormatter;
}

- (NSString *)stringFromDate:(NSDate *)date;

@end

@implementation LPTTYLogFormatter

- (NSString *)stringFromDate:(NSDate *)date {
  int32_t loggerCount = OSAtomicAdd32(0, &atomicLoggerCount);

  if (loggerCount <= 1) {
    // Single-threaded mode.

    if (!threadUnsafeDateFormatter) {
      threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
      [threadUnsafeDateFormatter setDateFormat:CalLogFormatterDateFormat];
    }

    return [threadUnsafeDateFormatter stringFromDate:date];
  } else {
    // Multi-threaded mode.
    // NSDateFormatter is NOT thread-safe.
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *dateFormatter = threadDictionary[CalLogFormatterDateFormatterKey];

    if (dateFormatter == nil) {
      dateFormatter = [[NSDateFormatter alloc] init];
      [dateFormatter setDateFormat:CalLogFormatterDateFormat];

      threadDictionary[CalLogFormatterDateFormatterKey] = dateFormatter;
    }

    return [dateFormatter stringFromDate:date];
  }
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
  NSString *logLevel;
  switch (logMessage.flag) {
    case DDLogFlagError    : logLevel = @"ERROR"; break;
    case DDLogFlagWarning  : logLevel = @" WARN"; break;
    case DDLogFlagInfo     : logLevel = @ "INFO"; break;
    case DDLogFlagDebug    : logLevel = @"DEBUG"; break;
    default                : logLevel = @"DEBUG"; break;
  }

  NSString *dateAndTime = [self stringFromDate:(logMessage.timestamp)];
  NSString *logMsg = logMessage->_message;

  NSString *filenameAndNumber = [NSString stringWithFormat:@"%@:%@",
                                 logMessage->_fileName, @(logMessage->_line)];
  return [NSString stringWithFormat:@"%@ %@ %@ | %@",
          dateAndTime,
          logLevel,
          filenameAndNumber,
          logMsg];
}

- (void)didAddToLogger:(id <DDLogger>)logger {
  OSAtomicIncrement32(&atomicLoggerCount);
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger {
  OSAtomicDecrement32(&atomicLoggerCount);
}
@end
