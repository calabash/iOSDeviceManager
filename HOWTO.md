## How To


### Compare .xctestconfiguration

When a new Xcode version drops we need to check that there are no new
or missing keys in the .xctestconfiguration template.

#### 0. Build iOSDeviceManager

Make sure your active Xcode is correct:

```
$ xcodebuild -version
```

If you are targetting, for example, an iOS 13 device, you must use at least
Xcode 11.

```
# Will stage binary to Products/iOSDeviceManager
$ make build
```

#### 1. Generate an .xctestconfiguration using Xcode

From Xcode, run an XCUITest and then download the -Runner AppData.

You can use Xcode > Device window to download the AppData.xcappdata bundle or
you can use:

```
Products/iOSDeviceManager download-xcappdata \
  path/to/your/-Runner.app \ # be sure it is built with the right Xcode!
  path/to/download/.xcarchive/to \
  <device-udid>
```

#### 2. Generate an .xctestconfiguration using iOSDeviceManager

You must have a -Runner.app and an AUT.app.

```
$ rm -rf xctestconfig
$ Products/iOSDeviceManager upload-xctestconf \
  path/to/AUT.app \
  path/to/Test-Runner.app \
  -d <udid of physical device>
```

This will generate a configuration file in a local xcestconfig/ directory.

#### 3. Compare the Versions

```
$ Products/iOSDeviceManager xctestconfig path/to/xcode/generated/<>.xctestconfiguration
$ Products/iOSDeviceManager xctestconfig xctestconfig/<>.xctestconfiguration
```

The values will be different.  We are interesting in new or missing keys.
