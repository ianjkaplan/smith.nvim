.PHONY: test lint format check clean help

# Default target
.DEFAULT_GOAL := help

# Directories
TESTS_DIR := tests
PLUGIN_DIR := lua

# Tools
NVIM := nvim
LUACHECK := luacheck
STYLUA := stylua

# Test configuration
PLENARY_DIR ?= /tmp/plenary.nvim
MINIMAL_INIT := $(TESTS_DIR)/minimal_init.lua

## test: Run all tests with plenary
test:
	@echo "Running tests..."
	@PLENARY_DIR=$(PLENARY_DIR) $(NVIM) \
		--headless \
		--noplugin \
		-u $(MINIMAL_INIT) \
		-c "PlenaryBustedDirectory $(TESTS_DIR) {minimal_init = '$(MINIMAL_INIT)', sequential = true}"

## test-file: Run a specific test file (usage: make test-file FILE=tests/smith/smith_spec.lua)
test-file:
	@echo "Running test file: $(FILE)"
	@PLENARY_DIR=$(PLENARY_DIR) $(NVIM) \
		--headless \
		--noplugin \
		-u $(MINIMAL_INIT) \
		-c "PlenaryBustedFile $(FILE)"

## lint: Run luacheck linter
lint:
	@echo "Running luacheck..."
	@$(LUACHECK) $(PLUGIN_DIR) $(TESTS_DIR) --config .luacheckrc

## format: Format code with stylua
format:
	@echo "Formatting with stylua..."
	@$(STYLUA) $(PLUGIN_DIR) $(TESTS_DIR) plugin

## format-check: Check formatting without modifying files
format-check:
	@echo "Checking formatting..."
	@$(STYLUA) --check $(PLUGIN_DIR) $(TESTS_DIR) plugin

## check: Run all checks (lint + format-check + test)
check: lint format-check test
	@echo "All checks passed!"

## clean: Clean temporary files
clean:
	@echo "Cleaning..."
	@rm -rf /tmp/plenary.nvim
	@find . -name "*.orig" -delete
	@find . -name "*~" -delete

## deps: Install/update development dependencies
deps:
	@echo "Installing plenary.nvim for testing..."
	@if [ ! -d "$(PLENARY_DIR)" ]; then \
		git clone https://github.com/nvim-lua/plenary.nvim $(PLENARY_DIR); \
	else \
		cd $(PLENARY_DIR) && git pull; \
	fi
	@echo "Dependencies ready!"
	@echo ""
	@echo "Make sure you have installed:"
	@echo "  - luacheck: luarocks install luacheck"
	@echo "  - stylua: cargo install stylua"

## help: Show this help message
help:
	@echo "smith.nvim - Neovim Plugin Development"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /'
