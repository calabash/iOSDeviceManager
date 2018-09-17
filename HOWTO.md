## How To


### Compare .xctestconfiguration

When a new Xcode version drops we need to check that there are no new
or missing keys in the .xctestconfiguration template.

#### 1. Generate an .xctestconfiguration using Xcode

From Xcode, run an XCUITest and then download the -Runner AppData.

You can use Xcode > Device window to download the AppData.xcappdata bundle or
you can use `iOSDeviceManager download-xcappdata`.

#### 2. Generate an .xctestconfiguration using iOSDeviceManager

You must have a -Runner.app and an AUT.app.

```
$ iOSDeviceManager upload-xctestconf \
  path/to/AUT.app \
  path/to/Test-Runner.app \
  -d <udid of physical device>
```

This will generate a configuration file in a local xcestconfig/ directory.

#### 3. Compare the Versions

```
$ iOSDeviceManager xctestconfig path/to/xcode/generated/<>.xctestconfiguration
$ iOSDeviceManager xctestconfig xctestconfig/<>.xctestconfiguration
```

The values will be different.  We are interesting in new or missing keys.
