
.PHONY: build
.PHONY: tests
.PHONY: frameworks

clean:
	rm -rf build

build:
	bin/make/build.sh

frameworks:
	bin/make/frameworks.sh

unit-tests:
	bin/test/unit.sh

integration-tests:
	bin/test/integration.sh

cli-tests:
	bin/test/cli.sh
rspec:
	bin/test/rspec.sh

tests:
	$(MAKE) unit-tests
	$(MAKE) integration-tests
	$(MAKE) cli-tests
