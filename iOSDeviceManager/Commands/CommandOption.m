
#import "CommandOption.h"

@implementation CommandOption

+ (instancetype)withShortFlag:(const NSString *)shortFlag
                     longFlag:(NSString *)longFlag
                   optionName:(NSString *)optionName
                         info:(NSString *)info
                     required:(BOOL)required
                    defaultVal:(NSString *)defaultValue {
    CommandOption *co = [CommandOption new];
    co.shortFlag = shortFlag;
    co.longFlag = longFlag;
    co.optionName = optionName;
    co.additionalInfo = info ?: @"";
    co.required = required;
    co.defaultValue = defaultValue;
    co.requiresArgument = YES;
    return co;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@,%@ <%@> DEFAULT=%@ [%@]",
            super.description,
            self.shortFlag,
            self.longFlag,
            self.optionName,
            self.defaultValue,
            self.required ? @"REQUIRED" : @"OPTIONAL"];
}

- (instancetype)asBooleanOption {
    CommandOption *boolCopy = [CommandOption withShortFlag:self.shortFlag
                                                  longFlag:self.longFlag
                                                optionName:self.optionName
                                                      info:self.additionalInfo
                                                  required:self.required
                                                defaultVal:self.defaultValue];
    boolCopy.requiresArgument = NO;
    return boolCopy;
}
@end
