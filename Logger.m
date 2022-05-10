//
//  Logger.m
//  iOSDeviceManager
//
//  Created by Ilya Bausov on 4/7/22.
//  Copyright © 2022 Microsoft. All rights reserved.
//

#import "Logger.h"

@implementation Logger

+ (os_log_t)logger {
    return os_log_create("Logger", "Tracing");
}

@end
