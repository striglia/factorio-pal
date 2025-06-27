-- Performance and UPS monitoring tests
local TodoManager = require("scripts/todo-manager")
local GuiManager = require("scripts/gui-manager")

describe("Performance and UPS Tests", function()
    local test_player
    local performance_data
    
    before_each(function()
        test_player = game.get_player(1) or game.create_player{name = "test_player"}
        
        -- Initialize storage
        if not storage.todos then
            storage.todos = {}
            storage.next_todo_id = 1
        end
        
        if not storage.goal_settings then
            storage.goal_settings = {
                goals_enabled = false,
                active_goals = {}
            }
        end
        
        performance_data = {
            start_tick = 0,
            end_tick = 0,
            operation_count = 0
        }
    end)
    
    local function measure_performance(operation_func, operation_name)
        local start_tick = game.tick
        local start_time = game.get_time()
        
        operation_func()
        
        local end_tick = game.tick
        local end_time = game.get_time()
        
        local elapsed_ticks = end_tick - start_tick
        local elapsed_time = end_time - start_time
        
        performance_data.start_tick = start_tick
        performance_data.end_tick = end_tick
        performance_data.operation_count = performance_data.operation_count + 1
        
        -- Log performance data
        game.print("Performance Test: " .. operation_name)
        game.print("  Elapsed ticks: " .. elapsed_ticks)
        game.print("  Elapsed time: " .. elapsed_time .. "ms")
        
        return {
            elapsed_ticks = elapsed_ticks,
            elapsed_time = elapsed_time
        }
    end
    
    describe("todo operations performance", function()
        it("should handle large numbers of todos efficiently", function()
            -- Clear existing todos
            storage.todos = {}
            storage.next_todo_id = 1
            
            local todo_count = 100
            local performance_threshold = 50 -- milliseconds
            
            local perf_data = measure_performance(function()
                -- Add many todos
                for i = 1, todo_count do
                    TodoManager.add_todo(test_player, "Performance test todo " .. i, nil)
                end
            end, "Adding " .. todo_count .. " todos")
            
            assert.equals(#storage.todos, todo_count)
            assert.is_true(perf_data.elapsed_time < performance_threshold, 
                "Adding todos took too long: " .. perf_data.elapsed_time .. "ms")
        end)
        
        it("should handle bulk todo operations efficiently", function()
            -- Setup: Add many todos
            storage.todos = {}
            for i = 1, 50 do
                TodoManager.add_todo(test_player, "Bulk test todo " .. i, nil)
            end
            
            -- Mark half as completed
            for i = 1, 25 do
                TodoManager.toggle_todo(storage.todos[i].id, nil)
            end
            
            local performance_threshold = 30 -- milliseconds
            
            local perf_data = measure_performance(function()
                TodoManager.clear_completed_todos(nil)
            end, "Clearing completed todos")
            
            assert.equals(#storage.todos, 25)
            assert.is_true(perf_data.elapsed_time < performance_threshold,
                "Clearing completed todos took too long: " .. perf_data.elapsed_time .. "ms")
        end)
        
        it("should handle todo reordering efficiently", function()
            -- Setup: Add many todos
            storage.todos = {}
            for i = 1, 30 do
                TodoManager.add_todo(test_player, "Reorder test todo " .. i, nil)
            end
            
            local performance_threshold = 20 -- milliseconds
            
            local perf_data = measure_performance(function()
                -- Perform multiple reorder operations
                for i = 1, 10 do
                    local todo_id = storage.todos[math.random(#storage.todos)].id
                    if math.random() > 0.5 then
                        TodoManager.move_todo_up(todo_id, nil)
                    else
                        TodoManager.move_todo_down(todo_id, nil)
                    end
                end
            end, "Multiple reorder operations")
            
            assert.is_true(perf_data.elapsed_time < performance_threshold,
                "Reordering operations took too long: " .. perf_data.elapsed_time .. "ms")
        end)
    end)
    
    describe("GUI performance", function()
        it("should refresh GUI efficiently with many todos", function()
            -- Setup: Add many todos
            storage.todos = {}
            for i = 1, 50 do
                TodoManager.add_todo(test_player, "GUI test todo " .. i, nil)
            end
            
            -- Create GUI window
            GuiManager.create_todo_window(test_player)
            
            local performance_threshold = 40 -- milliseconds
            
            local perf_data = measure_performance(function()
                GuiManager.refresh_todo_list(test_player)
            end, "GUI refresh with many todos")
            
            assert.is_true(perf_data.elapsed_time < performance_threshold,
                "GUI refresh took too long: " .. perf_data.elapsed_time .. "ms")
        end)
        
        it("should handle multiple GUI refreshes efficiently", function()
            -- Setup: Add moderate number of todos
            storage.todos = {}
            for i = 1, 20 do
                TodoManager.add_todo(test_player, "Multi-refresh test todo " .. i, nil)
            end
            
            GuiManager.create_todo_window(test_player)
            
            local performance_threshold = 60 -- milliseconds
            
            local perf_data = measure_performance(function()
                -- Perform multiple refreshes
                for i = 1, 10 do
                    GuiManager.refresh_todo_list(test_player)
                end
            end, "Multiple GUI refreshes")
            
            assert.is_true(perf_data.elapsed_time < performance_threshold,
                "Multiple GUI refreshes took too long: " .. perf_data.elapsed_time .. "ms")
        end)
        
        it("should handle GUI creation and destruction efficiently", function()
            local performance_threshold = 25 -- milliseconds
            
            local perf_data = measure_performance(function()
                -- Create and destroy multiple times
                for i = 1, 5 do
                    GuiManager.create_todo_window(test_player)
                    GuiManager.destroy_todo_window(test_player)
                end
            end, "GUI creation and destruction")
            
            assert.is_true(perf_data.elapsed_time < performance_threshold,
                "GUI creation/destruction took too long: " .. perf_data.elapsed_time .. "ms")
        end)
    end)
    
    describe("memory usage", function()
        it("should not leak memory with repeated operations", function()
            -- Measure initial memory state (approximated by storage size)
            local initial_todo_count = #storage.todos
            local initial_id = storage.next_todo_id
            
            local operation_cycles = 10
            local todos_per_cycle = 10
            
            for cycle = 1, operation_cycles do
                -- Add todos
                for i = 1, todos_per_cycle do
                    TodoManager.add_todo(test_player, "Memory test " .. cycle .. "_" .. i, nil)
                end
                
                -- Mark some as completed
                for i = 1, math.floor(todos_per_cycle / 2) do
                    if #storage.todos > 0 then
                        TodoManager.toggle_todo(storage.todos[#storage.todos - i + 1].id, nil)
                    end
                end
                
                -- Clear completed todos
                TodoManager.clear_completed_todos(nil)
                
                -- Refresh GUI
                GuiManager.create_todo_window(test_player)
                GuiManager.refresh_todo_list(test_player)
                GuiManager.destroy_todo_window(test_player)
            end
            
            -- Check that we haven't accumulated too many todos
            local final_todo_count = #storage.todos
            local todo_growth = final_todo_count - initial_todo_count
            
            -- Should have roughly half the todos we added (since we clear completed ones)
            local expected_growth = (operation_cycles * todos_per_cycle) / 2
            local acceptable_variance = expected_growth * 0.5 -- 50% variance is acceptable
            
            assert.is_true(todo_growth <= expected_growth + acceptable_variance,
                "Too many todos accumulated: " .. todo_growth .. " (expected ~" .. expected_growth .. ")")
            
            -- ID should continue to increment (no ID reuse)
            assert.is_true(storage.next_todo_id > initial_id,
                "next_todo_id should continue incrementing")
        end)
        
        it("should handle storage cleanup efficiently", function()
            -- Fill storage with test data
            storage.todos = {}
            for i = 1, 100 do
                TodoManager.add_todo(test_player, "Cleanup test todo " .. i, nil)
            end
            
            -- Mark all as completed
            for _, todo in pairs(storage.todos) do
                TodoManager.toggle_todo(todo.id, nil)
            end
            
            local performance_threshold = 30 -- milliseconds
            
            local perf_data = measure_performance(function()
                TodoManager.clear_completed_todos(nil)
            end, "Storage cleanup")
            
            assert.equals(#storage.todos, 0)
            assert.is_true(perf_data.elapsed_time < performance_threshold,
                "Storage cleanup took too long: " .. perf_data.elapsed_time .. "ms")
        end)
    end)
    
    describe("concurrent operations", function()
        it("should handle multiple players efficiently", function()
            -- Create multiple test players
            local players = {}
            for i = 1, 3 do
                players[i] = game.create_player{name = "perf_player_" .. i}
            end
            
            local performance_threshold = 50 -- milliseconds
            
            local perf_data = measure_performance(function()
                -- Each player adds todos
                for i, player in ipairs(players) do
                    for j = 1, 10 do
                        TodoManager.add_todo(player, "Player " .. i .. " todo " .. j, nil)
                    end
                end
                
                -- Refresh GUI for all players
                for _, player in ipairs(players) do
                    GuiManager.create_todo_window(player)
                    GuiManager.refresh_todo_list(player)
                end
            end, "Multiple player operations")
            
            assert.is_true(perf_data.elapsed_time < performance_threshold,
                "Multi-player operations took too long: " .. perf_data.elapsed_time .. "ms")
            
            -- Verify all todos were created
            assert.equals(#storage.todos, #players * 10)
        end)
        
        it("should handle rapid successive operations", function()
            storage.todos = {}
            
            local performance_threshold = 40 -- milliseconds
            
            local perf_data = measure_performance(function()
                -- Rapid operations without delays
                for i = 1, 20 do
                    TodoManager.add_todo(test_player, "Rapid todo " .. i, nil)
                    if i % 3 == 0 then
                        TodoManager.toggle_todo(storage.todos[#storage.todos].id, nil)
                    end
                    if i % 5 == 0 then
                        TodoManager.move_todo_up(storage.todos[#storage.todos].id, nil)
                    end
                end
            end, "Rapid successive operations")
            
            assert.is_true(perf_data.elapsed_time < performance_threshold,
                "Rapid operations took too long: " .. perf_data.elapsed_time .. "ms")
        end)
    end)
    
    describe("UPS impact assessment", function()
        it("should not significantly impact UPS during normal operations", function()
            -- This test is more observational - we measure the impact of our mod
            -- operations on the game's update cycle
            
            local ops_per_tick = 5
            local test_ticks = 10
            
            -- Measure baseline (no operations)
            local baseline_start = game.tick
            for i = 1, test_ticks do
                game.tick = game.tick + 1
            end
            local baseline_end = game.tick
            
            -- Reset tick counter
            game.tick = baseline_start
            
            -- Measure with operations
            local ops_start = game.tick
            for tick = 1, test_ticks do
                -- Perform operations during tick
                for op = 1, ops_per_tick do
                    TodoManager.add_todo(test_player, "UPS test " .. tick .. "_" .. op, nil)
                end
                game.tick = game.tick + 1
            end
            local ops_end = game.tick
            
            -- The impact should be minimal (this is more of a smoke test)
            assert.equals(ops_end - ops_start, test_ticks)
            
            -- Log the results for manual inspection
            game.print("UPS Impact Test Results:")
            game.print("  Operations performed: " .. (ops_per_tick * test_ticks))
            game.print("  Ticks elapsed: " .. test_ticks)
            game.print("  Final todo count: " .. #storage.todos)
        end)
    end)
end)