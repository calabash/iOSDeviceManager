
#
#	Cleans the build directory used by Xcode


.PHONY: build
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
	$(MAKE) fbframeworks
	bin/make/dependencies.sh

nuget: 
	$(MAKE) dependencies
	bin/make/nuget.sh

fbframeworks:
	bin/make/frameworks.sh

