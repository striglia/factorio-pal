-- Test runner for factorio-todo mod
-- This file sets up and runs all tests using FactorioTest framework

local FactorioTest = require("__factorio-test__.factorio-test")

-- Test configuration
local test_config = {
  timeout = 60, -- seconds
  print_passed_tests = true,
  print_failed_tests = true
}

-- Initialize test runner
local test_runner = FactorioTest.new(test_config)

-- Register test files
test_runner:add_test_file("tests/todo_manager_test")
test_runner:add_test_file("tests/gui_manager_test")
test_runner:add_test_file("tests/goals_manager_test")
test_runner:add_test_file("tests/persistence_test")
test_runner:add_test_file("tests/performance_test")

-- Run all tests
test_runner:run_all()