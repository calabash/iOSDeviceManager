
.PHONY: build
.PHONY: tests

#
#	Cleans the build directory used by make scripts.
#
clean:
	rm -rf build

#
#	Builds the executable
#
build:
	bin/make/build.sh

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
# 	Runs the unit tests.
#
test-unit:
	bin/make/test-unit.sh

#
# 	Runs the integration tests.
#
test-integration:
	bin/make/test-integration.sh

#
# 	Runs the integration tests.
#
tests:
	$(MAKE) test-unit
	$(MAKE) test-integration

