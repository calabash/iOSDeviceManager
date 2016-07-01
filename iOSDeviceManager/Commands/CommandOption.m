
#import "CommandOption.h"

@implementation CommandOption
+ (instancetype)withShortFlag:(NSString *)shortFlag
                     longFlag:(NSString *)longFlag
                   optionName:(NSString *)optionName
                         info:(NSString *)info
                     required:(BOOL)required {
    CommandOption *co = [CommandOption new];
    co.shortFlag = shortFlag;
    co.longFlag = longFlag;
    co.optionName = optionName;
    co.additionalInfo = info ?: @"";
    co.required = required;
    return co;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@,%@ <%@> [%@]",
            super.description,
            self.shortFlag,
            self.longFlag,
            self.optionName,
            self.required ? @"REQUIRED" : @"OPTIONAL"];
}
@end
