-- Tests for save/load persistence
local TodoManager = require("scripts/todo-manager")

describe("Persistence", function()
    local test_player
    
    before_each(function()
        test_player = game.get_player(1) or game.create_player{name = "test_player"}
        
        -- Initialize clean storage
        storage.todos = {}
        storage.next_todo_id = 1
    end)
    
    describe("global storage persistence", function()
        it("should maintain todos across save/load cycles", function()
            -- Create test data
            local test_todos = {
                "Build iron smelters",
                "Set up oil processing", 
                "Research advanced circuits"
            }
            
            -- Add todos
            for _, text in ipairs(test_todos) do
                TodoManager.add_todo(test_player, text, nil)
            end
            
            -- Mark one as completed
            TodoManager.toggle_todo(storage.todos[2].id, nil)
            
            -- Store current state
            local pre_save_state = {
                todo_count = #storage.todos,
                next_id = storage.next_todo_id,
                completed_count = 0,
                todo_texts = {}
            }
            
            for _, todo in pairs(storage.todos) do
                table.insert(pre_save_state.todo_texts, todo.text)
                if todo.completed then
                    pre_save_state.completed_count = pre_save_state.completed_count + 1
                end
            end
            
            -- Force save operation (simulated by accessing storage)
            local saved_todos = {}
            for i, todo in ipairs(storage.todos) do
                saved_todos[i] = {
                    id = todo.id,
                    text = todo.text,
                    completed = todo.completed,
                    owner = todo.owner,
                    created = todo.created,
                    order = todo.order,
                    progress = todo.progress
                }
            end
            
            -- Simulate load operation by reconstructing storage
            storage.todos = saved_todos
            
            -- Verify persistence
            assert.equals(#storage.todos, pre_save_state.todo_count)
            assert.equals(storage.next_todo_id, pre_save_state.next_id)
            
            local post_load_completed = 0
            for _, todo in pairs(storage.todos) do
                if todo.completed then
                    post_load_completed = post_load_completed + 1
                end
                
                -- Verify todo structure is maintained
                assert.is_not_nil(todo.id)
                assert.is_not_nil(todo.text)
                assert.is_not_nil(todo.owner)
                assert.is_not_nil(todo.created)
                assert.is_not_nil(todo.order)
                assert.is_boolean(todo.completed)
            end
            
            assert.equals(post_load_completed, pre_save_state.completed_count)
        end)
        
        it("should handle empty storage gracefully", function()
            -- Ensure empty storage doesn't cause errors
            storage.todos = {}
            storage.next_todo_id = 1
            
            -- Should not crash when accessing empty storage
            local todo_count = #storage.todos
            assert.equals(todo_count, 0)
            
            -- Should handle operations on empty storage
            TodoManager.clear_completed_todos(nil)
            assert.equals(#storage.todos, 0)
        end)
        
        it("should preserve todo properties after multiple operations", function()
            -- Add initial todo
            TodoManager.add_todo(test_player, "Test persistence", nil)
            local todo_id = storage.todos[1].id
            local original_created = storage.todos[1].created
            local original_owner = storage.todos[1].owner
            
            -- Perform various operations
            TodoManager.toggle_todo(todo_id, nil)
            TodoManager.toggle_todo(todo_id, nil) -- Toggle back
            
            -- Add more todos for reordering
            TodoManager.add_todo(test_player, "Second todo", nil)
            TodoManager.add_todo(test_player, "Third todo", nil)
            
            TodoManager.move_todo_down(todo_id, nil)
            TodoManager.move_todo_up(todo_id, nil)
            
            -- Find the original todo
            local persistent_todo = nil
            for _, todo in pairs(storage.todos) do
                if todo.id == todo_id then
                    persistent_todo = todo
                    break
                end
            end
            
            -- Verify properties are maintained
            assert.is_not_nil(persistent_todo)
            assert.equals(persistent_todo.text, "Test persistence")
            assert.equals(persistent_todo.created, original_created)
            assert.equals(persistent_todo.owner, original_owner)
            assert.is_false(persistent_todo.completed)
        end)
        
        it("should maintain next_todo_id consistency", function()
            local initial_id = storage.next_todo_id
            
            -- Add several todos
            for i = 1, 5 do
                TodoManager.add_todo(test_player, "Todo " .. i, nil)
            end
            
            -- Delete some todos
            TodoManager.delete_todo(storage.todos[2].id, test_player, nil)
            TodoManager.delete_todo(storage.todos[3].id, test_player, nil)
            
            -- next_todo_id should not go backwards
            assert.is_true(storage.next_todo_id >= initial_id + 5)
            
            -- New todos should still get unique IDs
            local pre_add_id = storage.next_todo_id
            TodoManager.add_todo(test_player, "New todo after deletions", nil)
            
            assert.equals(storage.next_todo_id, pre_add_id + 1)
            
            -- Verify no ID conflicts
            local ids = {}
            for _, todo in pairs(storage.todos) do
                assert.is_nil(ids[todo.id], "Duplicate ID found: " .. todo.id)
                ids[todo.id] = true
            end
        end)
    end)
    
    describe("data integrity", function()
        it("should handle corrupted storage gracefully", function()
            -- Simulate partially corrupted storage
            storage.todos = {
                {id = 1, text = "Valid todo", completed = false, owner = "test", created = 100, order = 1},
                {id = 2, text = nil, completed = false, owner = "test", created = 200, order = 2}, -- corrupted
                {id = 3, text = "Another valid todo", completed = true, owner = "test", created = 300, order = 3}
            }
            storage.next_todo_id = 4
            
            -- Operations should handle corrupted data without crashing
            local success = pcall(function()
                TodoManager.clear_completed_todos(nil)
            end)
            
            assert.is_true(success)
            
            -- Valid todos should remain
            local valid_todos = 0
            for _, todo in pairs(storage.todos) do
                if todo.text then
                    valid_todos = valid_todos + 1
                end
            end
            
            assert.is_true(valid_todos >= 1)
        end)
        
        it("should maintain order consistency", function()
            -- Add todos with specific orders
            for i = 1, 5 do
                TodoManager.add_todo(test_player, "Todo " .. i, nil)
            end
            
            -- Perform operations that modify order
            TodoManager.move_todo_up(storage.todos[3].id, nil)
            TodoManager.move_todo_down(storage.todos[1].id, nil)
            TodoManager.clear_completed_todos(nil)
            
            -- Sort by order and verify consistency
            table.sort(storage.todos, function(a, b) return a.order < b.order end)
            
            for i, todo in ipairs(storage.todos) do
                -- Orders should be reasonable (though not necessarily consecutive due to operations)
                assert.is_true(todo.order > 0)
                assert.is_true(todo.order <= #storage.todos * 2) -- Allow some order gaps
            end
        end)
    end)
end)