
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

build-lib:
	bin/make/build-lib.sh

dependencies:
	bin/make/dependencies.sh

fbframeworks:
	bin/make/frameworks.sh

facebook-frameworks:
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
#       Runs the run loop integration tests.
#
test-run-loop:
	bin/make/test-run-loop.sh

#
# 	Runs the integration tests.
#
tests:
	$(MAKE) test-unit
	$(MAKE) test-integration
	$(MAKE) test-run-loop
