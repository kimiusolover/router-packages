.PHONY: check test-tiny-plan test-source-lock test-ax23v-entrypoint test-router-prefix build-% build-ax23v-%

check:
	./packaging/check

test-tiny-plan:
	bash ./packaging/test-tiny-plan

test-source-lock:
	bash ./packaging/test-source-lock

test-ax23v-entrypoint:
	bash ./packaging/test-ax23v-entrypoint

test-router-prefix:
	bash ./packaging/test-router-prefix

build-%:
	./packaging/build-package "$*"

build-ax23v-%:
	./packaging/build-ax23v-package "$*"

.PHONY: test-preview-package
test-preview-package:
	python3 ./packaging/test-preview-package
