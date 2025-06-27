-- Tests for TodoManager module
local TodoManager = require("scripts/todo-manager")

describe("TodoManager", function()
    local test_player
    local initial_todo_count
    local mock_refresh_called
    
    local function mock_refresh()
        mock_refresh_called = true
    end
    
    before_each(function()
        -- Set up test environment
        test_player = game.get_player(1) or game.create_player{name = "test_player"}
        
        -- Initialize storage if not exists
        if not storage.todos then
            storage.todos = {}
            storage.next_todo_id = 1
        end
        
        initial_todo_count = #storage.todos
        mock_refresh_called = false
    end)
    
    describe("add_todo", function()
        it("should add a new todo with correct properties", function()
            local test_text = "Build more iron smelters"
            local initial_id = storage.next_todo_id
            
            TodoManager.add_todo(test_player, test_text, mock_refresh)
            
            assert.equals(#storage.todos, initial_todo_count + 1)
            
            local new_todo = storage.todos[#storage.todos]
            assert.equals(new_todo.text, test_text)
            assert.equals(new_todo.owner, test_player.name)
            assert.equals(new_todo.id, initial_id)
            assert.is_false(new_todo.completed)
            assert.is_not_nil(new_todo.created)
            assert.is_true(mock_refresh_called)
        end)
        
        it("should not add empty todos", function()
            TodoManager.add_todo(test_player, "", mock_refresh)
            
            assert.equals(#storage.todos, initial_todo_count)
            assert.is_false(mock_refresh_called)
        end)
        
        it("should increment next_todo_id", function()
            local initial_id = storage.next_todo_id
            
            TodoManager.add_todo(test_player, "Test todo", mock_refresh)
            
            assert.equals(storage.next_todo_id, initial_id + 1)
        end)
        
        it("should parse resource tracking goals", function()
            TodoManager.add_todo(test_player, "Produce 1000 iron plates", mock_refresh)
            
            local new_todo = storage.todos[#storage.todos]
            assert.is_not_nil(new_todo.progress)
        end)
    end)
    
    describe("toggle_todo", function()
        it("should toggle todo completion status", function()
            -- Add a test todo
            TodoManager.add_todo(test_player, "Test toggle", mock_refresh)
            local todo_id = storage.todos[#storage.todos].id
            mock_refresh_called = false
            
            -- Toggle to completed
            TodoManager.toggle_todo(todo_id, mock_refresh)
            
            local todo = nil
            for _, t in pairs(storage.todos) do
                if t.id == todo_id then
                    todo = t
                    break
                end
            end
            
            assert.is_not_nil(todo)
            assert.is_true(todo.completed)
            assert.is_true(mock_refresh_called)
            
            -- Toggle back to incomplete
            mock_refresh_called = false
            TodoManager.toggle_todo(todo_id, mock_refresh)
            assert.is_false(todo.completed)
            assert.is_true(mock_refresh_called)
        end)
        
        it("should handle non-existent todo_id gracefully", function()
            TodoManager.toggle_todo(99999, mock_refresh)
            
            -- Should not crash and should still call refresh
            assert.is_true(mock_refresh_called)
        end)
    end)
    
    describe("delete_todo", function()
        it("should delete todo when owner matches", function()
            -- Add a test todo
            TodoManager.add_todo(test_player, "Test delete", mock_refresh)
            local todo_id = storage.todos[#storage.todos].id
            local initial_count = #storage.todos
            mock_refresh_called = false
            
            TodoManager.delete_todo(todo_id, test_player, mock_refresh)
            
            assert.equals(#storage.todos, initial_count - 1)
            assert.is_true(mock_refresh_called)
            
            -- Verify todo is actually gone
            local found = false
            for _, todo in pairs(storage.todos) do
                if todo.id == todo_id then
                    found = true
                    break
                end
            end
            assert.is_false(found)
        end)
        
        it("should not delete todo when owner does not match", function()
            -- Add a test todo
            TodoManager.add_todo(test_player, "Test delete protection", mock_refresh)
            local todo_id = storage.todos[#storage.todos].id
            local initial_count = #storage.todos
            mock_refresh_called = false
            
            -- Try to delete with different player
            local other_player = game.create_player{name = "other_player"}
            TodoManager.delete_todo(todo_id, other_player, mock_refresh)
            
            assert.equals(#storage.todos, initial_count)
            assert.is_false(mock_refresh_called)
        end)
    end)
    
    describe("clear_completed_todos", function()
        it("should remove all completed todos and reorder remaining", function()
            -- Add test todos
            TodoManager.add_todo(test_player, "Todo 1", nil)
            TodoManager.add_todo(test_player, "Todo 2", nil)
            TodoManager.add_todo(test_player, "Todo 3", nil)
            
            -- Mark some as completed
            local todos_to_complete = {}
            for i = 1, 2 do
                if storage.todos[#storage.todos - (3-i)] then
                    table.insert(todos_to_complete, storage.todos[#storage.todos - (3-i)].id)
                end
            end
            
            for _, todo_id in pairs(todos_to_complete) do
                TodoManager.toggle_todo(todo_id, nil)
            end
            
            local initial_count = #storage.todos
            mock_refresh_called = false
            
            TodoManager.clear_completed_todos(mock_refresh)
            
            -- Should have fewer todos
            assert.is_true(#storage.todos < initial_count)
            assert.is_true(mock_refresh_called)
            
            -- All remaining todos should be incomplete
            for _, todo in pairs(storage.todos) do
                assert.is_false(todo.completed)
            end
            
            -- Orders should be consecutive starting from 1
            table.sort(storage.todos, function(a, b) return a.order < b.order end)
            for i, todo in ipairs(storage.todos) do
                assert.equals(todo.order, i)
            end
        end)
    end)
    
    describe("move_todo_up", function()
        it("should move todo up in order", function()
            -- Clear existing todos for clean test
            storage.todos = {}
            
            -- Add test todos
            TodoManager.add_todo(test_player, "First todo", nil)
            TodoManager.add_todo(test_player, "Second todo", nil)
            TodoManager.add_todo(test_player, "Third todo", nil)
            
            local second_todo_id = storage.todos[2].id
            local original_second_order = storage.todos[2].order
            local original_first_order = storage.todos[1].order
            
            mock_refresh_called = false
            TodoManager.move_todo_up(second_todo_id, mock_refresh)
            
            assert.is_true(mock_refresh_called)
            
            -- Find the moved todo
            local moved_todo = nil
            for _, todo in pairs(storage.todos) do
                if todo.id == second_todo_id then
                    moved_todo = todo
                    break
                end
            end
            
            assert.is_not_nil(moved_todo)
            assert.equals(moved_todo.order, original_first_order)
        end)
        
        it("should not move first todo up", function()
            storage.todos = {}
            TodoManager.add_todo(test_player, "Only todo", nil)
            
            local todo_id = storage.todos[1].id
            local original_order = storage.todos[1].order
            
            mock_refresh_called = false
            TodoManager.move_todo_up(todo_id, mock_refresh)
            
            assert.is_false(mock_refresh_called)
            assert.equals(storage.todos[1].order, original_order)
        end)
    end)
    
    describe("move_todo_down", function()
        it("should move todo down in order", function()
            storage.todos = {}
            
            TodoManager.add_todo(test_player, "First todo", nil)
            TodoManager.add_todo(test_player, "Second todo", nil)
            TodoManager.add_todo(test_player, "Third todo", nil)
            
            local first_todo_id = storage.todos[1].id
            local original_first_order = storage.todos[1].order
            local original_second_order = storage.todos[2].order
            
            mock_refresh_called = false
            TodoManager.move_todo_down(first_todo_id, mock_refresh)
            
            assert.is_true(mock_refresh_called)
            
            local moved_todo = nil
            for _, todo in pairs(storage.todos) do
                if todo.id == first_todo_id then
                    moved_todo = todo
                    break
                end
            end
            
            assert.is_not_nil(moved_todo)
            assert.equals(moved_todo.order, original_second_order)
        end)
        
        it("should not move last todo down", function()
            storage.todos = {}
            TodoManager.add_todo(test_player, "Only todo", nil)
            
            local todo_id = storage.todos[1].id
            local original_order = storage.todos[1].order
            
            mock_refresh_called = false
            TodoManager.move_todo_down(todo_id, mock_refresh)
            
            assert.is_false(mock_refresh_called)
            assert.equals(storage.todos[1].order, original_order)
        end)
    end)
end)