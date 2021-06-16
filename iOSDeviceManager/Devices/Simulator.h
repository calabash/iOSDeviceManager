
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <XCTestBootstrap/XCTestBootstrap.h>
#import "Device.h"
@import Foundation;

@interface Simulator : Device<FBXCTestReporter, FBControlCoreLogger>

+ (NSURL *)simulatorAppURL;

+ (iOSReturnStatusCode)launchSimulator:(Simulator *)simulator;
+ (iOSReturnStatusCode)killSimulatorApp;
+ (iOSReturnStatusCode)eraseSimulator:(Simulator *)simulator;

@end
