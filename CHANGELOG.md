### 1.0.4

FBSimulatorControl was not updated.  See the 1.0.3 notes for details.

* Remove DeviceAgent.iOS.Deployment #99
* CLI.json is no longer necessary for the iOSDeviceManager binary #96

### 1.0.3

Includes [facebook/FBSimulatorControl 0.2.2 @ f0cc887](https://github.com/calabash/FBSimulatorControl/commit/f0cc8874a9fc1474e278db7571f8c35b9f88a354).

The corresponding calabash/FBSimulatorControl tag is [fb-0.2.2-at-f0cc887](https://github.com/calabash/FBSimulatorControl/releases/tag/fb-0.2.2-at-f0cc887-iOSDeviceManager-1.0.3)

* Match array-based entitlements with * and <TEAM ID>. #95
* FB Frameworks 0.2.2 with Sierra + Xcode >= 8.1 support #94
* Fix timeout by using mach\_absolute\_time() #93
* Fix ShasumProvider generating strings with missing characters. #92
* Upload files to application's data container #91
* Update to Facebook frameworks to 0.2.2 #89
* Use CocoaLumberjack provided by FBSimulatorControl #85
* Fix cannot find XCTBootstrap.framework compile time errors #83
* Simplify how we get the common name for a certificate #82
* Use CommonCrypto to get SHA1 instead of shelling out #80

### 1.0.2

* Update fb frameworks (rm dup ref) #68
* Update to include frameworks from /pull/12 #67
* Feature/daemonize update frameworks #65
* Update FBFrameworks #64
* FIXUP: Sign the sim app bundle with the ad hoc signature '-' #63
* Update session-id default #61
* Feature/daemonize add http frameworks #60
* Update fb frameworks #59
* Make entitlement match robust to different entitlement formats #58
* Find usable codesign identity when not specified #53
