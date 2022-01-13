### 3.9.2

* Updated idb frameworks from version 1.1.6.
* Fixed deprecations and reworked Simulator lifecycle methods.
* Added support of Xcode 13.2.1.

### 3.9.1

* Updated deployment target to 11.0 and fixed deprecated methods.
* Fixed DeviceUtils issue with launching default simulator for Xcode 13.1.
* Fixed unit tests.
* Decreased delay for a simulator launch.

### 3.9.0

* Xcode 13 and 13.1 Support.
* Started migration from idb fork to it's origin.
* Fixed some bugs.

### 3.8.1

* Xcode 12.5 Support

### 3.8.0

* Xcode 12.4 Support

### 3.7.4

* FB Frameworks: add missing simulators and devices

### 3.7.3

A release that contains resigned FaceBook frameworks.  Our developer account
expired unexpectedly.

Force signing with Mac Developer account (instead of Apple Developer on Xcode 11)

#### FBSimulatorControl

Force signing with Mac Developer account (instead of Apple Developer on Xcode 11)

* https://github.com/calabash/FBSimulatorControl/releases/tag/0.4.0-Xcode-11.2.1
* macOS Mojave 10.14.6
* Xcode 11.2.1

### 3.7.1

* Add 'Apple Development' string to isIOSDeveloperIdentity() #263

Thank you @papalma

### 3.7.0

#### FBSimulatorControl

* https://github.com/calabash/FBSimulatorControl/releases/tag/0.4.0-Xcode-11.2
* macOS Mojave 10.14.6
* Xcode 11.2.1

### 3.6.0

* FB Frameworks: add missing simulators and devices
* https://github.com/calabash/FBSimulatorControl/releases/tag/0.4.0-Xcode-11.2
* macOS Mojave 10.14.6
* Xcode 11.1

### 3.5.0

* Add support for Xcode 10.3 #254

### 3.4.0

* Add support for Xcode 11 #246
* Build: add signing step for CocoaLumber framework #245
* resigning: Use sha1 and sha256 digest algorighms #244

### 3.3.1

* Adapt iOSDeviceManager to Xcode 10.2 #241
* Xcode 10.2 update code signing test fixtures #240

* FB Frameworks built from tag/0.4.0-Xcode-10.2.0
  - Xcode 10.2 GM
  - macOS Mojave

### 3.3.0

* Fixed default simulator selection #236
* Added compatibility with new device ids #238

### 3.2.2

* FB Frameworks: handle missing simulator arches #234

FBSimulatorControl libraries built from calabash fork off /develop
branch @ a6687f10632a49d61df60c6817a7746ffd44a832, Xcode 10.0,
and maco High Sierra.

### 3.2.1

* Upload xctestconfig command requires file paths #320
* Frameworks: update FBSimControl related frameworks with new ios 12
  device models #231

### 3.2.0

This release provides support for Xcode 10 beta 6.

* Shell: all NSTask executed with timeout #219
* Fix simulator-by-alias/name algorithm #225
* Codesign is timing out on low resource machines #226
* Stablize Simulator app life cycle events for Xcode 10 beta 6 #228

### 3.1.1

This release provides support for Xcode 9.4.

* Commands: erase simulator command #209
* Frameworks: update frameworks #210

### 3.1.0

* Clear app data: remove temporary created .xcappdata bundle  #207
* Fixed is-installed command simulator bug #206
* Bin/Make: logical organization of make rules and scripts #205
* Update headers with MSFT OSS comment #204
* Add clear-app-data and download-xcappdata commands #203

calabash/FBSimulatorControl built from this tag:

https://github.com/calabash/FBSimulatorControl/releases/tag/0.4.0-2018.04.09-iOS-11.3-and-Xcode-93-support%2BMSFT_OSS_comments

### 3.0.0

This release provides support for Xcode >= 9.3.

* Project: remove server components #201
* Replace install --update-app with --force flag and fix behavior #200
* Xcode 9.3 and iOS 11.3 support #199
* Ask if app is installed only once during app installation #193

calabash/FBSimulatorControl built from this tag:

https://github.com/calabash/FBSimulatorControl/releases/tag/0.4.0-2018.02.20-iOS-11.3-and-Xcode-93-support

### 2.1.2

This release provides fixes for Xcode >= 9.0.1.

* Update FBSimulatorControl frameworks to fix various Xcode > 9.0
  problems #191
* CLI: remove start-test command and sources #190
* CLI: commands for decoding xctestconfiguration files #189

calabash/FBSimulatorControl built from this tag:

https://github.com/calabash/FBSimulatorControl/releases/tag/0.4.0-2017.11.08-missing-devices-and-fix-device-console-hanging

### 2.1.1

* Enforce correct simulator state before app life cycle events #187

### 2.1.0

Support for Xcode 9/iOS 11.

* Simulator#launch: launches the simulator #185

calabash/FBSimulatorControl built from this tag:

* https://github.com/calabash/FBSimulatorControl/releases/tag/0.4.0-2017.08.18-patch-CoreSim-linking

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
