
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

dependencies:
	bin/make/dependencies.sh

fbframeworks:
	bin/make/frameworks.sh

facebook-frameworks:
	bin/make/frameworks.sh

test-unit:
	bin/make/test-unit.sh

test-integration:
	bin/make/test-integration.sh

test-cli:
	bin/test/cli.sh

test-run-loop:
	bin/make/test-run-loop.sh

tests:
	$(MAKE) test-unit
	$(MAKE) test-integration
	$(MAKE) test-cli
	$(MAKE) test-run-loop
