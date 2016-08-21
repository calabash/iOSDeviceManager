
.PHONY: build

#
#	Cleans the build directory used by Xcode
#
clean:
	rm -rf build

#
#	Installs the FBSimulatorControl frameworks to ~/.calabash/Frameworks
#
install_frameworks:
	bin/install_frameworks.sh

#
#	Builds the executable
#
# If this fails, call 'make clean' and try again.
build:
	bin/build.sh

#
# 	Installs to /usr/local/bin
#
install:
	$(MAKE) clean
	$(MAKE) install_frameworks
	$(MAKE) build
	bin/install.sh


dependencies:
	bin/make/dependencies.sh

nuget:
	$(MAKE) dependencies
	bin/make/nuget.sh

fbframeworks:
	bin/make/frameworks.sh

#
# 	Runs the XCTests
#
xctest:
	bin/test/xctest.sh

