#import <Foundation/Foundation.h>

@interface CommandOption : NSObject
@property (nonatomic, strong) NSString *shortFlag;
@property (nonatomic, strong) NSString *longFlag;
@property (nonatomic, strong) NSString *optionName;
@property (nonatomic, strong) NSString *additionalInfo;
@property (nonatomic)       BOOL required;

+ (instancetype)withShortFlag:(NSString *)shortFlag
                     longFlag:(NSString *)longFlag
                   optionName:(NSString *)optionName
                         info:(NSString *)info
                     required:(BOOL)required;
@end
