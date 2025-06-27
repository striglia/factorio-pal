-- Tests for GuiManager module
local GuiManager = require("scripts/gui-manager")
local TodoManager = require("scripts/todo-manager")
local mod_gui = require("__core__.lualib.mod-gui")

describe("GuiManager", function()
    local test_player
    
    before_each(function()
        test_player = game.get_player(1) or game.create_player{name = "test_player"}
        
        -- Initialize storage
        if not storage.todos then
            storage.todos = {}
            storage.next_todo_id = 1
        end
        
        if not storage.goal_settings then
            storage.goal_settings = {
                goals_enabled = false
            }
        end
        
        -- Clean up any existing GUI elements
        GuiManager.destroy_todo_window(test_player)
        GuiManager.destroy_todo_button(test_player)
    end)
    
    after_each(function()
        -- Clean up GUI elements after each test
        GuiManager.destroy_todo_window(test_player)
        GuiManager.destroy_todo_button(test_player)
    end)
    
    describe("todo button management", function()
        it("should create todo button", function()
            GuiManager.create_todo_button(test_player)
            
            local button_flow = mod_gui.get_button_flow(test_player)
            assert.is_not_nil(button_flow.todo_button)
            assert.equals(button_flow.todo_button.type, "sprite-button")
            assert.equals(button_flow.todo_button.name, "todo_button")
        end)
        
        it("should not create duplicate todo buttons", function()
            GuiManager.create_todo_button(test_player)
            GuiManager.create_todo_button(test_player) -- Second call
            
            local button_flow = mod_gui.get_button_flow(test_player)
            assert.is_not_nil(button_flow.todo_button)
            
            -- Should still only have one button (no error from duplicate creation)
            local button_count = 0
            for name, element in pairs(button_flow.children_names) do
                if name == "todo_button" then
                    button_count = button_count + 1
                end
            end
            assert.equals(button_count, 1)
        end)
        
        it("should destroy todo button", function()
            GuiManager.create_todo_button(test_player)
            local button_flow = mod_gui.get_button_flow(test_player)
            assert.is_not_nil(button_flow.todo_button)
            
            GuiManager.destroy_todo_button(test_player)
            assert.is_nil(button_flow.todo_button)
        end)
        
        it("should handle destroying non-existent button gracefully", function()
            local button_flow = mod_gui.get_button_flow(test_player)
            assert.is_nil(button_flow.todo_button)
            
            -- Should not error
            local success = pcall(function()
                GuiManager.destroy_todo_button(test_player)
            end)
            assert.is_true(success)
        end)
    end)
    
    describe("todo window management", function()
        it("should create todo window with proper structure", function()
            local window = GuiManager.create_todo_window(test_player)
            
            assert.is_not_nil(window)
            assert.equals(window.name, "todo_window")
            assert.equals(window.type, "frame")
            
            -- Check for essential components
            assert.is_not_nil(window.input_flow)
            assert.is_not_nil(window.input_flow.todo_input)
            assert.is_not_nil(window.input_flow.add_todo_button)
            assert.is_not_nil(window.todo_scroll)
            assert.is_not_nil(window.todo_scroll.todo_list)
            assert.is_not_nil(window.controls_flow)
            assert.is_not_nil(window.controls_flow.clear_completed_button)
        end)
        
        it("should show enable goals button when goals disabled", function()
            storage.goal_settings.goals_enabled = false
            
            local window = GuiManager.create_todo_window(test_player)
            
            assert.is_not_nil(window.controls_flow.enable_goals_button)
        end)
        
        it("should not show enable goals button when goals enabled", function()
            storage.goal_settings.goals_enabled = true
            
            local window = GuiManager.create_todo_window(test_player)
            
            assert.is_nil(window.controls_flow.enable_goals_button)
        end)
        
        it("should not create duplicate windows", function()
            local window1 = GuiManager.create_todo_window(test_player)
            local window2 = GuiManager.create_todo_window(test_player)
            
            assert.equals(window1, window2) -- Should return same window
            
            local frame_flow = mod_gui.get_frame_flow(test_player)
            assert.is_not_nil(frame_flow.todo_window)
        end)
        
        it("should destroy todo window", function()
            GuiManager.create_todo_window(test_player)
            local frame_flow = mod_gui.get_frame_flow(test_player)
            assert.is_not_nil(frame_flow.todo_window)
            
            GuiManager.destroy_todo_window(test_player)
            assert.is_nil(frame_flow.todo_window)
        end)
    end)
    
    describe("todo list display", function()
        it("should show empty message when no todos", function()
            storage.todos = {}
            
            GuiManager.create_todo_window(test_player)
            GuiManager.refresh_todo_list(test_player)
            
            local frame_flow = mod_gui.get_frame_flow(test_player)
            local todo_list = frame_flow.todo_window.todo_scroll.todo_list
            
            -- Should have one child (the empty message label)
            assert.equals(#todo_list.children, 1)
            assert.equals(todo_list.children[1].type, "label")
        end)
        
        it("should display todos with proper structure", function()
            storage.todos = {}
            TodoManager.add_todo(test_player, "Test todo 1", nil)
            TodoManager.add_todo(test_player, "Test todo 2", nil)
            
            GuiManager.create_todo_window(test_player)
            GuiManager.refresh_todo_list(test_player)
            
            local frame_flow = mod_gui.get_frame_flow(test_player)
            local todo_list = frame_flow.todo_window.todo_scroll.todo_list
            
            -- Should have two todo flows
            assert.equals(#todo_list.children, 2)
            
            for i, todo_flow in ipairs(todo_list.children) do
                assert.equals(todo_flow.type, "flow")
                assert.is_not_nil(todo_flow.children_names["todo_checkbox_" .. storage.todos[i].id])
                assert.is_not_nil(todo_flow.children_names["text_progress_flow_" .. storage.todos[i].id])
                assert.is_not_nil(todo_flow.children_names["reorder_flow_" .. storage.todos[i].id])
            end
        end)
        
        it("should show delete button only for todo owner", function()
            storage.todos = {}
            TodoManager.add_todo(test_player, "My todo", nil)
            
            -- Create another player
            local other_player = game.create_player{name = "other_player"}
            TodoManager.add_todo(other_player, "Other's todo", nil)
            
            GuiManager.create_todo_window(test_player)
            GuiManager.refresh_todo_list(test_player)
            
            local frame_flow = mod_gui.get_frame_flow(test_player)
            local todo_list = frame_flow.todo_window.todo_scroll.todo_list
            
            -- First todo (owned by test_player) should have delete button
            local first_todo_flow = todo_list.children[1]
            local has_delete_button = false
            for name, _ in pairs(first_todo_flow.children_names) do
                if string.match(name, "delete_todo_") then
                    has_delete_button = true
                    break
                end
            end
            assert.is_true(has_delete_button)
            
            -- Second todo (owned by other_player) should not have delete button for test_player
            local second_todo_flow = todo_list.children[2]
            local has_delete_button_2 = false
            for name, _ in pairs(second_todo_flow.children_names) do
                if string.match(name, "delete_todo_") then
                    has_delete_button_2 = true
                    break
                end
            end
            assert.is_false(has_delete_button_2)
        end)
        
        it("should display progress bars for trackable todos", function()
            storage.todos = {}
            
            -- Add todo with progress tracking
            TodoManager.add_todo(test_player, "Produce 100 iron plates", nil)
            
            -- Manually set progress info for testing
            if storage.todos[1].progress then
                storage.todos[1].progress.trackable = true
                storage.todos[1].progress.current_count = 25
                storage.todos[1].progress.target_count = 100
            end
            
            GuiManager.create_todo_window(test_player)
            GuiManager.refresh_todo_list(test_player)
            
            local frame_flow = mod_gui.get_frame_flow(test_player)
            local todo_list = frame_flow.todo_window.todo_scroll.todo_list
            local todo_flow = todo_list.children[1]
            local text_progress_flow = todo_flow.children_names["text_progress_flow_" .. storage.todos[1].id]
            
            -- Should have progress bar
            local has_progress_bar = false
            for name, element in pairs(text_progress_flow.children_names) do
                if string.match(name, "progress_bar_") and element.type == "progressbar" then
                    has_progress_bar = true
                    break
                end
            end
            assert.is_true(has_progress_bar)
        end)
        
        it("should disable reorder buttons appropriately", function()
            storage.todos = {}
            TodoManager.add_todo(test_player, "First todo", nil)
            TodoManager.add_todo(test_player, "Second todo", nil)
            TodoManager.add_todo(test_player, "Third todo", nil)
            
            GuiManager.create_todo_window(test_player)
            GuiManager.refresh_todo_list(test_player)
            
            local frame_flow = mod_gui.get_frame_flow(test_player)
            local todo_list = frame_flow.todo_window.todo_scroll.todo_list
            
            -- First todo: up button should be disabled
            local first_reorder_flow = todo_list.children[1].children_names["reorder_flow_" .. storage.todos[1].id]
            local first_up_button = first_reorder_flow.children_names["move_up_" .. storage.todos[1].id]
            assert.is_false(first_up_button.enabled)
            
            -- Last todo: down button should be disabled
            local last_reorder_flow = todo_list.children[3].children_names["reorder_flow_" .. storage.todos[3].id]
            local last_down_button = last_reorder_flow.children_names["move_down_" .. storage.todos[3].id]
            assert.is_false(last_down_button.enabled)
            
            -- Middle todo: both buttons should be enabled
            local middle_reorder_flow = todo_list.children[2].children_names["reorder_flow_" .. storage.todos[2].id]
            local middle_up_button = middle_reorder_flow.children_names["move_up_" .. storage.todos[2].id]
            local middle_down_button = middle_reorder_flow.children_names["move_down_" .. storage.todos[2].id]
            assert.is_true(middle_up_button.enabled)
            assert.is_true(middle_down_button.enabled)
        end)
    end)
    
    describe("refresh functionality", function()
        it("should handle refreshing non-existent window gracefully", function()
            -- Should not error when window doesn't exist
            local success = pcall(function()
                GuiManager.refresh_todo_list(test_player)
            end)
            assert.is_true(success)
        end)
        
        it("should refresh for all connected players", function()
            -- Create windows for multiple players
            local player2 = game.create_player{name = "player2"}
            
            GuiManager.create_todo_window(test_player)
            GuiManager.create_todo_window(player2)
            
            TodoManager.add_todo(test_player, "Shared todo", nil)
            
            -- Should not error when refreshing for all players
            local success = pcall(function()
                GuiManager.refresh_todo_list_for_all_players()
            end)
            assert.is_true(success)
        end)
    end)
end)