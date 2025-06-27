# Factorio Mod Development Makefile

# Lua interpreter for standalone testing
LUA ?= lua

# Test commands
.PHONY: test test-lua test-factorio test-syntax help install-deps

test: test-syntax ## Run all available tests (syntax check + show manual test commands)
	@echo ""
	@echo "✅ Syntax validation passed!"
	@echo ""
	@echo "For integration tests, run in Factorio console:"
	@echo "  /c require('tests/test_runner')"
	@echo ""
	@echo "Or run individual test suites:"
	@echo "  /c require('tests/todo_manager_test')"
	@echo "  /c require('tests/gui_manager_test')"
	@echo "  /c require('tests/goals_manager_test')"
	@echo "  /c require('tests/persistence_test')"
	@echo "  /c require('tests/performance_test')"

test-syntax: ## Validate Lua syntax for all mod files
	@echo "Checking Lua syntax..."
	@find ./factorio-todo -name "*.lua" -not -path "*/tests/*" -exec lua -c {} \; 2>/dev/null && echo "✅ All mod files have valid syntax" || (echo "❌ Syntax errors found in mod files" && exit 1)
	@find ./factorio-todo/tests -name "*.lua" -exec lua -c {} \; 2>/dev/null && echo "✅ All test files have valid syntax" || (echo "❌ Syntax errors found in test files" && exit 1)

test-lua: ## Run standalone Lua unit tests (if any exist)
	@echo "Running standalone Lua tests..."
	@if command -v busted >/dev/null 2>&1; then \
		echo "Running tests with Busted..."; \
		busted --pattern="_test%.lua$$" tests/; \
	elif [ -f "tests/unit_test_runner.lua" ]; then \
		echo "Running custom Lua test runner..."; \
		$(LUA) tests/unit_test_runner.lua; \
	else \
		echo "ℹ️  No standalone Lua tests found. Use 'make test-factorio' for integration tests."; \
	fi

test-factorio: ## Show commands for running Factorio integration tests
	@echo "Factorio Integration Test Commands:"
	@echo ""
	@echo "Start Factorio and run in console:"
	@echo "  All tests:           /c require('tests/test_runner')"
	@echo "  Todo manager:        /c require('tests/todo_manager_test')"
	@echo "  GUI components:      /c require('tests/gui_manager_test')"
	@echo "  Goals integration:   /c require('tests/goals_manager_test')"
	@echo "  Save/load tests:     /c require('tests/persistence_test')"
	@echo "  Performance tests:   /c require('tests/performance_test')"
	@echo ""
	@echo "💡 Make sure the 'factorio-test' mod is installed!"

install-deps: ## Install testing dependencies
	@echo "Installing testing dependencies..."
	@if command -v luarocks >/dev/null 2>&1; then \
		echo "Installing Busted testing framework..."; \
		luarocks install busted; \
		echo "Installing Mockagne mocking library..."; \
		luarocks install mockagne; \
		echo "✅ Dependencies installed!"; \
	else \
		echo "❌ LuaRocks not found. Please install LuaRocks first:"; \
		echo "  macOS: brew install luarocks"; \
		echo "  Ubuntu: sudo apt-get install luarocks"; \
	fi

sync: ## Sync mod to Factorio mods directory (requires sync script)
	@echo "Syncing mod to Factorio..."
	@if [ -f "./sync-mod.sh" ]; then \
		./sync-mod.sh; \
	else \
		echo "❌ sync-mod.sh not found"; \
		echo "💡 Create a sync script or manually copy to Factorio mods directory"; \
	fi

lint: ## Check code style and potential issues
	@echo "Checking code style..."
	@if command -v luacheck >/dev/null 2>&1; then \
		luacheck . --ignore 111 --ignore 112 --ignore 113; \
	else \
		echo "ℹ️  luacheck not installed. Install with: luarocks install luacheck"; \
	fi

help: ## Show this help message
	@echo "Factorio Mod Development Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Testing Workflow:"
	@echo "  1. make test-syntax    - Validate Lua syntax"
	@echo "  2. make sync          - Copy mod to Factorio"
	@echo "  3. make test-factorio - Run integration tests in Factorio"

# Default target
.DEFAULT_GOAL := help