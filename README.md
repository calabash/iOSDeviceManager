## devicectl

A tool for launching xctests on device and simulator, and a library
for device/simulator lifecycle management.

### Using

```
$ devicectl
  -r       Path to Test Runner .app directory
  -t       Path to .xctest bundle
  -c       [Device Only] Codesign Identity
           e.g. "iPhone Developer: Aaron Aaronson (ABCDE12345)"
  -d       Device UDID
           e.g. Simulator: "F8C4D65B-2FB7-4B8B-89BE-8C3982E65F3F"
           e.g. Physical Device: 49a29c9e61998623e7909e35e8bae50dd07ef85f
```

### Building

`devicectl` has some framework dependencies on the FBSimulatorControl
frameworks.  A forked build of them is included in the project and can
be installed like so:

```
$ make install_frameworks
```

You can also run the general install script to build the tool and
install it to `/usr/local/bin`:

```
$ make install
```

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

`devicectl` has an interface for C interop/FFI. 

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
