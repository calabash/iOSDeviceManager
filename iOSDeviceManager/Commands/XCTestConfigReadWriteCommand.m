
#import "XCTestConfigReadWriteCommand.h"
#import "XCTestConfigurationProxy.h"
#import "XCTestConfigurationPlist.h"
#import "ConsoleWriter.h"

/*
 # Print to stdout
 xctestconfig [input-file]

 # Print and write to .plist
 xctestconfig [input-file] [output-file] --overwrite true/false

 # Print xctestconfiguration template to stdout
 xctestconfig --print-template
 */

@implementation XCTestConfigReadWriteCommand

+ (NSString *)name {
    return @"xctestconfig";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    NSString *inputFile = args[@"input-file"];

    if ([@"--print-template" isEqualToString:inputFile]) {
      ConsoleWrite(@"%@", [XCTestConfigurationPlist template]);
      return iOSReturnStatusCodeEverythingOkay;
    }

    NSFileManager *manager = [NSFileManager defaultManager];

    if (![manager fileExistsAtPath:inputFile]) {
      ConsoleWriteErr(@"Input file does not exist at path:");
      ConsoleWriteErr(@"  %@", inputFile);
      return iOSReturnStatusCodeInvalidArguments;
    }

    if (![@"xctestconfiguration" isEqualToString:[inputFile pathExtension]]) {
      ConsoleWriteErr(@"Input file does not have .xctestconfiguration extension:");
      ConsoleWriteErr(@"  %@", inputFile);
      return iOSReturnStatusCodeInvalidArguments;
    }

    XCTestConfigurationProxy *config;
    config = [XCTestConfigurationProxy configurationWithContentsOfFile:inputFile];

    if (!config) {
        return iOSReturnStatusCodeGenericFailure;
    }

    NSString *outputFile = args[@"output-file"];

    if (!outputFile) {
      ConsoleWrite(@"%@", config);
      return iOSReturnStatusCodeEverythingOkay;
    } else {
      BOOL overwrite;
      if (args[@"--overwrite"]) {
        overwrite = YES;
      } else {
        overwrite = NO;
      }

      if ([config writeToPlistFile:outputFile overwrite:overwrite]) {
        return iOSReturnStatusCodeEverythingOkay;
      } else {
        return iOSReturnStatusCodeGenericFailure;
      }
    }
}

+ (NSArray <CommandOption *> *)options {
  static NSArray<CommandOption *> *options;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    options =
        @[
            [CommandOption withPosition:0
                             optionName:@"input-file"
                                   info:@"Path to an .xctestconfiguration file or --print-template to print .xctestconfig template"
                               required:YES
                             defaultVal:nil],

            [CommandOption withPosition:1
                             optionName:@"output-file"
                                   info:@"Where to write the XCTestConfiguration to a .plist"
                               required:NO
                             defaultVal:nil],

            [CommandOption withPosition:2
                             optionName:@"--overwrite"
                                   info:@"When writing, should an existing .plist be overwritten"
                               required:NO
                             defaultVal:nil],
        ];
  });
  return options;
}

@end
