
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
@end
