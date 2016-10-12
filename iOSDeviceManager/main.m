
#import "CLI.h"
#import "LPTTYLogFormatter.h"
#import <FBControlCore/CalabashUtils.h>

void setup_logger() {
    DDFileLogger *fileLogger = [DDFileLogger new];
    NSError *e;
    NSString *logsDir = [CalabashUtils logfileLocation:&e];
    
    if (logsDir && !e) {
        DDLogFileManagerDefault *logFileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:logsDir];
        fileLogger = [[DDFileLogger alloc] initWithLogFileManager:logFileManager];
    }
    
    //Logfile rolls every day or 1 mb of log
    fileLogger.rollingFrequency = 60 * 60 * 24;
    fileLogger.maximumFileSize = 1024 * 1024; //1Mb
    fileLogger.logFileManager.maximumNumberOfLogFiles = 10;
    fileLogger.logFormatter = [LPTTYLogFormatter new];
    [DDLog addLogger:fileLogger];
    
    if (e) {
        ConsoleWriteErr(@"Error creating logfile: %@", e);
    }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        setup_logger();
        return [CLI process:[NSProcessInfo processInfo].arguments];
    }
}
