### 2.1.0

Supports Xcode 9 GM.

Advancing the version to create a tag from which we can release
binaries built with Xcode 9 GM.

### 2.0.2

Really supports Xcode 9 beta 6.

* Test "is-installed" command from rspec #182
* FBiOSDeviceOperator is applicable to physical device only #181
* Update build scripts with new log.sh and common simctl loading
  function #179

calabash/FBSimulatorControl built from this tag:

* https://github.com/calabash/FBSimulatorControl/releases/tag/0.4.0-2017.08.18-swift-dylib-patch

### 2.0.1

Supports Xcode 9 beta 6.

* Terminate apps before uninstalling to prevent black
  screen/unresponsive apps on physical devices #177
* FBSimulatorControl: sync to 0.4.0 f7c5822 on Aug 18 2017 #176
* CLI for uploading in entire xcappdata bundles #175
* Fixes getting resources from args for install-app #172

calabash/FBSimulatorControl built from this tag:

* https://github.com/calabash/FBSimulatorControl/releases/tag/0.4.0-2017.08.18

### 2.0.0

* Stabilize and improve the resigning integration tests #168
* FBSimulatorControl includes ReturnAttributes key when inspecting
  installed applications #163
* Fetching applications before downloading app data prevents failures #162
* Xcode 9: can install provisioning profiles #161
* Add app-info command #160
* Fix file uploading when targeting physical devices #157
* upload command writes upload path to stdout #155
* CLI 2.0 #137

### 1.1.2

* Install command can inject resources #145
* Uninstall app before install to avoid "application-identifier
  entitlements mismatch" error #147
* Frameworks: guard against NULL return from FBAMDCreateDeviceList() #153

calabash/FBSimulatorControl built from this tag:

* [0.4.0-2017.04.19-guard-against-NULL](https://github.com/calabash/FBSimulatorControl/releases/tag/0.4.0-2017.04.19-guard-against-NULL)

### 1.1.1

I have omitted many pull requests.  For the full list see
https://github.com/calabash/iOSDeviceManager/milestone/6

There are some changes that should not be announced publicly.

* Simulator#launch: wait for required simulator sevices #131
* Xcode 8.3 support #126
* Add library version of iOSDeviceManager for interop w/ Test Recorder #120
* Integration test using run_loop ruby API #110
* implement ios-cli resigning algorithm and add CLI interface #108
* Improve default device detection #104
* Add support for app lifecycle events on .ipa archives #103
* Allow positional argument for device ID #102
* Stores identities rather than making multiple find-identity calls #101

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
