
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <XCTestBootstrap/XCTestBootstrap.h>
#import "Device.h"
@import Foundation;

@interface Simulator : Device<FBTestManagerTestReporter, FBControlCoreLogger>

+ (NSURL *)simulatorAppURL;

+ (iOSReturnStatusCode)launchSimulator:(Simulator *)simulator;
+ (iOSReturnStatusCode)killSimulatorApp;

@end
