## iOSDeviceManager

A tool for launching XCUITests on device and simulator, and a library
for device/simulator lifecycle management.

### Usage

```
USAGE: iOSDeviceManager [command] [flags]

start_test
-d,--device-id	<device-identifier>	iOS Simulator GUID or 40-digit physical device ID
-r,--test-runner	<path/to/testrunner.app>	Path to the test runner application which will run the test bundle
-t,--test-bundle	<path/to/testbundle.xctest>	Path to the .xctest bundle
-c,--codesign-identity	<codesign-identity> [OPTIONAL] 	Identity used to codesign application resources [device only]
-k,--keep-alive	<true-or-false> [OPTIONAL] 	Only set to false for smoke testing/debugging this tool

install
-d,--device-id	<device-identifier>	iOS Simulator GUID or 40-digit physical device ID
-a,--app-bundle	<path/to/app-bundle.app>	Path .app bundle (for .ipas, unzip and look inside of 'Payload')
-c,--codesign-identity	<codesign-identity> [OPTIONAL] 	Identity used to codesign app bundle [device only]

stop_simulating_location
-d,--device-id	<device-identifier> 40-digit physical device ID

launch_simulator
-d,--device-id	<device-identifier>	iOS Simulator GUID or 40-digit physical device ID

is_installed
-b,--bundle-identifier	<bundle-id>	bundle identifier (e.g. com.my.app)
-d,--device-id	<device-identifier>	iOS Simulator GUID or 40-digit physical device ID

kill_simulator
-d,--device-id	<device-identifier>	iOS Simulator GUID or 40-digit physical device ID

uninstall
-d,--device-id	<device-identifier>	iOS Simulator GUID or 40-digit physical device ID
-b,--bundle-identifier	<bundle-id>	bundle identifier (e.g. com.my.app)

set_location
-d,--device-id	<device-identifier>	iOS Simulator GUID or 40-digit physical device ID
-l,--location	<lat,lng>	latitude and longitude separated by a single comma

```

### Building

#### Code Signing

Starting in Xcode 8, a code signing identity is required for building.

Project maintainers must clone the [codesign](https://github.com/calabash-codesign)
repo and install the certs/identity. Talk to @jmoody or @sapieneptus
for details.

#### Packaging

To package all of the DeviceAgent dependencies together,

```shell
FBSIMCONTROL_PATH=/path/to/FBSimulatorControl \
DEVICEAGENT_PATH=/path/to/DeviceAgent.iOS \
make dependencies
```

This will gather all dependencies and put them in Distribution/dependencies.

To build a nuget package:

```shell
FBSIMCONTROL_PATH=/path/to/FBSimulatorControl \
DEVICEAGENT_PATH=/path/to/DeviceAgent.iOS \
make nuget
```

The resulting `.nupkg` is just a wrapper around these dependencies.

*Note* that you should have the calabash fork of FBSimulatorControl cloned.

### Contributing

Please see our [CONTRIBUTING](CONTRIBUTING) doc.

The majority of the actual work is inside of the
FBSimulatorControl fork. Therefore, logic adjustments will generally
need to be made in https://github.com/calabash/FBSimulatorControl.

For convenience, the fork is included in the `FacebookSubmodules`
directory of the project root. If you decide to branch the fork, it is
up to you to rebuild the frameworks and move them to the `Frameworks`
directory in the project root so that they will be installed when you
run `make install`.

### C Library

`iOSDeviceManager` has an interface for C interop/FFI.

```C
/**
 Start XCUITest
 @param deviceID 40 character device ID or Simulator GUID. Use `instruments -s devices` to list Sim IDs.
 @param testRunnerPath absolute path to test runner app (DeviceAgent app bundle)
 @param testBundlePath absolute path to test bundle (CBX.xctest)
 @param codesignID Identity used to codesign (for sims, this value is ignored).
 @return 0 on success, 1 on failure.

 Starts XC(UI)Test bundle specified by `testBundlePath` via the app specified by `testRunnerPath`.

 Attempts to install the test runner if not already installed.

 Will boot simulator if not already booted.
 */
int start_test(const char *deviceID,
               const char *testRunnerPath,
               const char *testBundlePath,
               const char *codesignID);

/**
 Launch simulator by ID
 @param simulatorID A simulator GUID
 @return 0 on success, 1 on failure

 If the sim is already running, does nothing.
 */
int launch_simulator(const char *simulatorID);

/**
 Kill simulator by ID
 @param simulatorID A simulator GUID
 @return 0 on success, 1 on failure.

 If sim isn't running, does nothing.
 */
int kill_simulator(const char *simulatorID);

/**
 Installs an app bundle. Acts as "upgrade install" (i.e. maintains app data of any previous installation).
 @param pathToBundle Absolute path to an app bundle. Note this must be a .app bundle, even for physical devices.
 @param deviceID 40 char device ID or simulator GUID
 @param codesignID Identity used to sign the bundle before installation. Ignored for sims apps.
 @return 0 if successful, 1 otherwise.

 As noted, for physical devices you also need an `.app` bundle. This can be found
 inside of an .ipa by unzipping it and looking inside of the resulting 'Payload'
 directory.

 E.g., `cd Foo; unzip -q MyApp.ipa` results in this:

 /Foo
 ├── Payload
 │   └── MyApp.app
 └── MyApp.ipa

 And what you want is `MyApp.app`.
 */
int install_app(const char *pathToBundle, const char *deviceID, const char *codesignID);

/**
 Uninstalls an app.
 @param bundleID bundle identifier of the app you want to remove
 @param deviceID 40 char device ID or simulator GUID.
 @return 0 if successful, 1 otherwise.
 */
int uninstall_app(const char *bundleID, const char *deviceID);

/**
 Checks if an app is installed
 @param bundleID bundle identifier of the app you want to remove
 @param deviceID 40 char device ID or simulator GUID.
 @return 1 if installed, 0 if not, -1 if error occurred.
 */
int is_installed(const char *bundleID, const char *deviceID);
```
