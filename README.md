## iOSDeviceManager

A tool for launching XCUITests on device and simulator, and a library
for device/simulator lifecycle management.

### Code Signing

Starting in Xcode 8, a code signing identity is required for building.

Project maintainers must clone the [codesign](https://github.com/calabash/calabash-codesign)
repo and install the certs and profiles. Talk to @jmoody or @sapieneptus
for details.

Contributors need to touch the Xcode project file with valid credentials.

### Building

```
$ git clone --recursive git@github.com:calabash/iOSDeviceManager.git
$ make build

# Usage
$ Products/iOSDeviceManager
```

### Testing

```
$ carthage bootstrap
$ make test-unit
$ make test-integration
$ make tests

# Test against an alternative Xcode
$ DEVELOPER_DIR=/Xcode/8.0/Xcode-beta.app/Contents/Developer make tests
```

If you encounter build errors in the Xcode IDE, clean the DerivedData
directory (deep clean - Command + Shift + Option + K).  You are likely
to see errors if you switch Xcode IDEs between runs.

If you have physical device attached and it is compatible with and
available to the active Xcode (the Xcode IDE or the returned by
xcode-select), integration tests will be performed against the device.
If no device is found, the tests are skipped.

### Packaging

```shell
# stage the dependences to ./Distribution/dependencies.
$ make dependencies

# Create .nupkg.
$ make nuget
```

The make `dependencies` and `nuget` rules expect the DeviceAgent.iOS repo
to be located in `../DeviceAgent.iOS`.  If your local copy of DeviceAgent.iOS
is in another location, use the `DEVICEAGENT_PATH` env var to specify
the correct path.

### Contributing

Please see our [CONTRIBUTING](CONTRIBUTING) doc.

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
