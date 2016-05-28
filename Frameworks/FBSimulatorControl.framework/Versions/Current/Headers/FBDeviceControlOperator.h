//
//  FBDeviceControlOperator.h
//  FBSimulatorControl
//
//  Created by Chris Fuentes on 5/11/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTestBootstrap/FBDeviceOperator.h>

/**
 TODO: annotate
 */
@interface FBDeviceControlOperator : NSObject<FBDeviceOperator>
+ (instancetype)deviceOperatorWithDeviceID:(NSString *)deviceID;
@end
