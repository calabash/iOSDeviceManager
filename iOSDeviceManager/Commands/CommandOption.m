
#import "CommandOption.h"

@implementation CommandOption

+ (instancetype)withShortFlag:(NSString *)shortFlag
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
@end
