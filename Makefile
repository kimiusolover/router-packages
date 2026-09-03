.PHONY: check test-tiny-plan test-source-lock test-ax23v-entrypoint test-router-prefix build-% build-ax23v-%

check:
	./packaging/check

test-tiny-plan:
	./packaging/test-tiny-plan

test-source-lock:
	./packaging/test-source-lock

test-ax23v-entrypoint:
	./packaging/test-ax23v-entrypoint

test-router-prefix:
	./packaging/test-router-prefix

build-%:
	./packaging/build-package "$*"

build-ax23v-%:
	./packaging/build-ax23v-package "$*"
