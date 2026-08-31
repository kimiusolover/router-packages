.PHONY: check test-tiny-plan test-source-lock build-%

check:
	./packaging/check

test-tiny-plan:
	./packaging/test-tiny-plan

test-source-lock:
	./packaging/test-source-lock

build-%:
	./packaging/build-package "$*"
