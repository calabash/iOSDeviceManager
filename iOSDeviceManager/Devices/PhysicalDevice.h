
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

@import Foundation;
#import "Device.h"
#import "FBLegacy.h"
#import <XCTestBootstrap/XCTestBootstrap.h>

@interface PhysicalDevice : Device<FBXCTestReporter, FBControlCoreLogger>
@end
