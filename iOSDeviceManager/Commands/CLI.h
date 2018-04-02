
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <Foundation/Foundation.h>
#import "iOSReturnStatusCode.h"

@interface CLI : NSObject
+ (iOSReturnStatusCode)process:(NSArray *)args;
@end
