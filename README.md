# test-control

A tool for launching xctests on device and simulator. 

# Using

```
test-control
       -r       Path to Test Runner .app directory
       -t       Path to .xctest bundle (probably inside the test runner's PlugIns directory)
       -c       [Device Only] Codesign Identity (e.g. 'iPhone Developer: Aaron Aaronson (ABCDE12345)')
       -d       Device ID e.g. 'F8C4D65B-2FB7-4B8B-89BE-8C3982E65F3F' (for Simulators),                              
                or 40 char Device ID for physical devices, e.g. 49a29c9e61998623e7909e35e8bae50dd07ef85f
```

# Building

`test-control` has some framework dependencies on the FBSimulatorControl frameworks. 
A forked build of them is included in the project and can be installed like so:

```
make install_frameworks
```

You can also run the general install script to build the tool and install it to `/usr/local/bin`:

```
make install
```

# Contributing
The majority of the actual work is inside of the FBSimulatorControl fork. Therefore, logic 
adjustments will generally need to be made in https://github.com/calabash/FBSimulatorControl. 

For convenience, the fork is included in the `FacebookSubmodules` directory of the project
root. If you decide to branch the fork, it is up to you to rebuild the frameworks and 
move them to the `Frameworks` directory in the project root so that they will be installed
when you run `make install`. 