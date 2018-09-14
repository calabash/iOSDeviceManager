| develop | [versioning](VERSIONING.md) | [license](LICENSE) | [contributing](CONTRIBUTING.md)|
|---------|-----------------------------|--------------------|--------------------------------|
|[![Build Status](https://calabash-ci.xyz/job/iOSDeviceManager/job/develop/badge/icon)](https://calabash-ci.xyz/job/iOSDeviceManager/job/develop) | [![Version](https://img.shields.io/badge/version-3.2.0-green.svg)](https://img.shields.io/badge/version-3.2.0-green.svg) |[![License](https://img.shields.io/github/license/mashape/apistatus.svg?maxAge=2592000)](LICENSE) | [![Contributing](https://img.shields.io/badge/contrib-gitflow-orange.svg)](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow/)|

## iOSDeviceManager

A command line tool for managing applications on iOS simulators and
physical iOS devices.

### Requirements

* Xcode >= 9.4.1
* ruby 2.3.x - ruby > 2.4 is not supported.

### Code Signing

Project maintainers must clone the [codesign](https://github.com/calabash/calabash-codesign)
repo and install the certs and profiles. Talk to a maintainer for details.

Contributors need to touch the Xcode project file with valid credentials.

### Building

```shell
$ git clone --recursive git@github.com:calabash/iOSDeviceManager.git
$ make build
```

### Usage

After building, you can run:

```shell
$ Products/iOSDeviceManager
```
to see usage information.

### Testing

```shell
$ make unit-tests
$ make integration-tests
$ make cli-tests

# Or just execute 'tests' to run all
$ make tests

# Test against an alternative Xcode
$ DEVELOPER_DIR=/Xcode/9.4.1/Xcode-beta.app/Contents/Developer make tests
```

If you encounter build errors in the Xcode IDE, clean the DerivedData
directory (deep clean - Command + Shift + Option + K).  You are likely
to see errors if you switch Xcode IDEs between runs.

If you have physical device attached and it is compatible with and
available to the active Xcode (the Xcode IDE or the returned by
xcode-select), integration tests will be performed against the device.
If no device is found, the tests are skipped.

The Expecta, Specta, and OCMock frameworks are controlled by Carthage.
We commit the frameworks to source control to avoid having to run
`carthage bootstrap` on CI machines and locally.  To update the
frameworks, run `carthage update` and commit the Cartfile.resolved and
frameworks changes to git.
