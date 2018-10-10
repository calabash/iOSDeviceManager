//
//  XCodeUtils.h
//  iOSDeviceManager
//
//  Created by Sergey Dolin on 10/10/2018.
//  Copyright © 2018 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCodeUtils : NSObject
+ (int) versionMajor;
+ (int) versionMinor;
@end

NS_ASSUME_NONNULL_END
