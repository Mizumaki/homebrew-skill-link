BATS ?= bats
SHELLCHECK ?= shellcheck

SCRIPT := bin/skill-link
TESTS_DIR := tests

.PHONY: test lint check help

test:
	$(BATS) $(TESTS_DIR)

lint:
	$(SHELLCHECK) $(SCRIPT)

check: lint test

help:
	@echo "Targets:"
	@echo "  test   Run the bats test suite ($(TESTS_DIR)/)"
	@echo "  lint   Run shellcheck on $(SCRIPT)"
	@echo "  check  Run lint then test"
