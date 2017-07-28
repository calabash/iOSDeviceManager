#import <Foundation/Foundation.h>

@interface CommandOption : NSObject
@property (nonatomic, strong) const NSString *shortFlag;
@property (nonatomic, strong) NSString *longFlag;
@property (nonatomic, strong) NSString *optionName;
@property (nonatomic, strong) NSString *additionalInfo;
@property (nonatomic, strong) id defaultValue;
@property (nonatomic)         NSUInteger position;
@property (nonatomic)         BOOL positional;
@property (nonatomic)         BOOL required;
@property (nonatomic)         BOOL requiresArgument;

+ (instancetype)withPosition:(NSUInteger)positionIndex
                   optionName:(NSString *)optionName
                         info:(NSString *)info
                     required:(BOOL)required
                   defaultVal:(id)defaultValue;

+ (instancetype)withShortFlag:(const NSString *)shortFlag
                     longFlag:(NSString *)longFlag
                   optionName:(NSString *)optionName
                         info:(NSString *)info
                     required:(BOOL)required
                   defaultVal:(id)defaultValue;

- (instancetype)asBooleanOption;

@end
