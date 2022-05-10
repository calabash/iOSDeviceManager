//
//  Logger.h
//  iOSDeviceManager
//
//  Created by Ilya Bausov on 4/7/22.
//  Copyright © 2022 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <os/log.h>

NS_ASSUME_NONNULL_BEGIN

@interface Logger : NSObject
+ (os_log_t)logger;
+ (void)LogVerbose:(NSString)message;
@end

NS_ASSUME_NONNULL_END
