#import "IDMLogger.h"
#import "CocoaLumberjack/DDTTYLogger.h"
#import "CocoaLumberjack/DDFileLogger.h"
#import <stdatomic.h>

#pragma mark - IDMLogFileManager

static NSString *const IDMLogFileNameDateFormat = @"yyyy-MM-dd-HH-mm-ss";
static NSString *const IDMLogFileNameDateFormatterKey = @"sh.calaba-IDMLogFileNameFormatter-NSDateFormatter";
static NSString *const IDMLogFilePrefix = @"idm-";

@interface DDLogFileManagerDefault (iOSDeviceManagerAdditions)

- (void)deleteOldLogFiles;

@end

@interface IDMLogFileManager : DDLogFileManagerDefault

@end

@implementation IDMLogFileManager


- (NSString *)newLogFileName {

  NSDateFormatter *dateFormatter = [self logFileDateFormatter];
  NSString *formattedDate = [dateFormatter stringFromDate:[NSDate date]];

  return [NSString stringWithFormat:@"%@%@.log", IDMLogFilePrefix, formattedDate];
}


- (NSDateFormatter *)logFileDateFormatter {
  NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
  NSString *dateFormat = IDMLogFileNameDateFormat;
  NSDateFormatter *dateFormatter = dictionary[IDMLogFileNameDateFormatterKey];

  if (dateFormatter == nil) {
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:dateFormat];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    dictionary[IDMLogFileNameDateFormatterKey] = dateFormatter;
  }

  return dateFormatter;
}

- (NSString *)createNewLogFileWithError:(NSError *__autoreleasing  _Nullable *)error {
  NSString *fileName = [self newLogFileName];
  NSString *logsDirectory = [self logsDirectory];

  NSString *path = [logsDirectory stringByAppendingPathComponent:fileName];
  while ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
    path = [logsDirectory stringByAppendingPathComponent:[self newLogFileName]];
  }

  NSDictionary *attributes = nil;

  [[NSFileManager defaultManager] createFileAtPath:path
                                          contents:nil
                                        attributes:attributes];


  [self deleteOldLogFiles];

  NSString *currentSymlink = [logsDirectory stringByAppendingPathComponent:@"current.log"];
  [[NSFileManager defaultManager] removeItemAtPath:currentSymlink error:nil];

  [[NSFileManager defaultManager] createSymbolicLinkAtPath:currentSymlink
                                       withDestinationPath:path error:nil];

  return path;
}

- (BOOL)isLogFile:(NSString *)fileName {

  BOOL hasProperPrefix = [fileName hasPrefix:IDMLogFilePrefix];
  BOOL hasProperSuffix = [fileName hasSuffix:@".log"];
  BOOL hasProperDate = NO;

  if (hasProperPrefix && hasProperSuffix) {
    NSUInteger lengthOfMiddle = fileName.length - IDMLogFilePrefix.length - @".log".length;

    // Date string should have at least 19 characters: "2013-12-03-17-14-10"
    if (lengthOfMiddle >= 19) {
      NSRange range = NSMakeRange(IDMLogFilePrefix.length, lengthOfMiddle);

      NSString *middle = [fileName substringWithRange:range];
      NSArray *components = [middle componentsSeparatedByString:@"-"];

      if (components.count == 6) {
        NSDateFormatter *dateFormatter = [self logFileDateFormatter];
        NSDate *date = [dateFormatter dateFromString:middle];

        if (date) {
          hasProperDate = YES;
        }
      }
    }
  }

  return (hasProperPrefix && hasProperDate && hasProperSuffix);
}

@end

static NSString *const IDMLogFormatterDateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
static NSString *const IDMLogFormatterDateFormatterKey = @"sh.calaba-IDMLogFormatter-NSDateFormatter";

@interface IDMLogFormatter : NSObject <DDLogFormatter>  {
  atomic_int_fast32_t atomicLoggerCount;
  NSDateFormatter *threadUnsafeDateFormatter;
}

- (NSString *)stringFromDate:(NSDate *)date;

@end


@implementation IDMLogFormatter

- (NSString *)stringFromDate:(NSDate *)date {
    int32_t loggerCount = atomic_fetch_add_explicit(&atomicLoggerCount, 0, memory_order_relaxed);

  if (loggerCount <= 1) {
    // Single-threaded mode.

    if (!threadUnsafeDateFormatter) {
      threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
      [threadUnsafeDateFormatter setDateFormat:IDMLogFormatterDateFormat];
    }

    return [threadUnsafeDateFormatter stringFromDate:date];
  } else {
    // Multi-threaded mode.
    // NSDateFormatter is NOT thread-safe.
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *dateFormatter = threadDictionary[IDMLogFormatterDateFormatterKey];

    if (dateFormatter == nil) {
      dateFormatter = [[NSDateFormatter alloc] init];
      [dateFormatter setDateFormat:IDMLogFormatterDateFormat];

      threadDictionary[IDMLogFormatterDateFormatterKey] = dateFormatter;
    }

    return [dateFormatter stringFromDate:date];
  }
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
  NSString *logLevel;
  switch (logMessage.flag) {
    case DDLogFlagError    : logLevel = @"ERROR"; break;
    case DDLogFlagWarning  : logLevel = @"WARN"; break;
    case DDLogFlagInfo     : logLevel = @"INFO"; break;
    case DDLogFlagDebug    : logLevel = @"DEBUG"; break;
    default                : logLevel = @"DEBUG"; break;
  }

  NSString *dateAndTime = [self stringFromDate:(logMessage.timestamp)];
  NSString *logMsg = logMessage->_message;

  NSString *filenameAndNumber = [NSString stringWithFormat:@"%@:%@",
                                 logMessage.fileName, @(logMessage.line)];
  return [NSString stringWithFormat:@"%@ %@ %@ | %@",
          dateAndTime,
          logLevel,
          filenameAndNumber,
          logMsg];
}

- (void)didAddToLogger:(id <DDLogger>)logger {
    atomic_fetch_add_explicit(&atomicLoggerCount, 1, memory_order_relaxed);
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger {
    atomic_fetch_add_explicit(&atomicLoggerCount, 1, memory_order_relaxed);
}

@end

#pragma mark - IDMLogger

@implementation IDMLogger

+ (void)startLumberjackLogging {

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
  // Xcode Console Logging - maybe enable this logger at runtime if we are
  // running from within the Xcode IDE or with xcodebuild test.
  // [[DDTTYLogger sharedInstance] setLogFormatter:[IDMLogFormatter new]];
  // [DDLog addLogger:[DDTTYLogger sharedInstance]];

  // Apple System Logger
  // [[DDASLLogger sharedInstance] setLogFormatter:[IDMLogFormatter new]];
  // [DDLog addLogger:[DDASLLogger sharedInstance]];

    NSString *logDirectory = [[[NSHomeDirectory()
                                stringByAppendingPathComponent:@".calabash"]
                               stringByAppendingPathComponent:@"iOSDeviceManager"]
                              stringByAppendingPathComponent:@"logs"];
    IDMLogFileManager *logFileManager = [[IDMLogFileManager alloc]
                                         initWithLogsDirectory:logDirectory];

    DDFileLogger *fileLogger = [[DDFileLogger alloc]
                                initWithLogFileManager:logFileManager];


    //Logfile rolls every day or 1 mb of log
    fileLogger.rollingFrequency = 60 * 60 * 24;
    fileLogger.maximumFileSize = 1024 * 1024; //1Mb
    fileLogger.logFileManager.maximumNumberOfLogFiles = 10;
    fileLogger.logFormatter = [IDMLogFormatter new];
    [DDLog addLogger:fileLogger];
  });
}

@end
