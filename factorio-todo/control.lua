-- Import modules
local TodoManager = require("scripts/todo-manager")
local ProgressTracker = require("scripts/progress-tracker")
local GuiManager = require("scripts/gui-manager")
local GoalsManager = require("scripts/goals-manager")

-- Initialize storage on game start
script.on_init(function()
    storage.todos = {}
    storage.next_todo_id = 1
    storage.goal_settings = {
        goals_enabled = false,
        active_goals = {}
    }
    storage.goals = {}
    storage.next_goal_id = 1
    storage.goal_links = {}
end)

-- Handle configuration changes (mod updates, etc.)
script.on_configuration_changed(function()
    if not storage.todos then
        storage.todos = {}
    end
    if not storage.next_todo_id then
        storage.next_todo_id = 1
    end
    if not storage.goal_settings then
        storage.goal_settings = {
            goals_enabled = false,
            active_goals = {}
        }
    end
    if not storage.goals then
        storage.goals = {}
    end
    if not storage.next_goal_id then
        storage.next_goal_id = 1
    end
    if not storage.goal_links then
        storage.goal_links = {}
    end
    -- Add order field to existing todos if missing
    for i, todo in ipairs(storage.todos) do
        if not todo.order then
            todo.order = i
        end
        -- Add progress field to existing todos if missing
        if not todo.progress then
            todo.progress = ProgressTracker.parse_resource_goal(todo.text)
        end
    end
end)

-- Set up periodic progress tracking
script.on_event(defines.events.on_tick, function(event)
    -- Update progress every 3 seconds (180 ticks at 60 UPS)
    if event.tick % 180 == 0 then
        ProgressTracker.update_progress_tracking(GuiManager.refresh_todo_list_for_all_players)
    end
end)

-- Handle player joining
script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.get_player(event.player_index)
    GuiManager.create_todo_button(player)
end)

-- Handle GUI clicks
script.on_event(defines.events.on_gui_click, function(event)
    local player = game.get_player(event.player_index)
    local element = event.element
    
    if element.name == "todo_button" then
        local frame_flow = require("__core__.lualib.mod-gui").get_frame_flow(player)
        if frame_flow.todo_window then
            GuiManager.destroy_todo_window(player)
        else
            GuiManager.create_todo_window(player)
            GuiManager.refresh_todo_list(player)
        end
    
    elseif element.name == "add_todo_button" then
        local frame_flow = require("__core__.lualib.mod-gui").get_frame_flow(player)
        if frame_flow.todo_window then
            local input = frame_flow.todo_window.input_flow.todo_input
            TodoManager.add_todo(player, input.text, GuiManager.refresh_todo_list_for_all_players)
            input.text = ""
        end
    
    elseif element.name == "clear_completed_button" then
        TodoManager.clear_completed_todos(GuiManager.refresh_todo_list_for_all_players)
    
    elseif string.match(element.name, "^todo_checkbox_(%d+)$") then
        local todo_id = tonumber(string.match(element.name, "^todo_checkbox_(%d+)$"))
        TodoManager.toggle_todo(todo_id, GuiManager.refresh_todo_list_for_all_players)
    
    elseif string.match(element.name, "^delete_todo_(%d+)$") then
        local todo_id = tonumber(string.match(element.name, "^delete_todo_(%d+)$"))
        TodoManager.delete_todo(todo_id, player, GuiManager.refresh_todo_list_for_all_players)
    
    elseif string.match(element.name, "^move_up_(%d+)$") then
        local todo_id = tonumber(string.match(element.name, "^move_up_(%d+)$"))
        TodoManager.move_todo_up(todo_id, GuiManager.refresh_todo_list_for_all_players)
    
    elseif string.match(element.name, "^move_down_(%d+)$") then
        local todo_id = tonumber(string.match(element.name, "^move_down_(%d+)$"))
        TodoManager.move_todo_down(todo_id, GuiManager.refresh_todo_list_for_all_players)
    
    -- Goals browser events
    elseif element.name == "enable_goals_button" then
        GoalsManager.create_goals_browser(player)
    
    elseif element.name == "goals_browser_close" then
        GoalsManager.destroy_goals_browser(player)
    
    elseif element.name == "goals_browser_apply" then
        GoalsManager.apply_goal_selections(player)
        GoalsManager.destroy_goals_browser(player)
        
        -- Refresh todo window to show/hide goals enable button
        GuiManager.destroy_todo_window(player)
        GuiManager.create_todo_window(player)
        GuiManager.refresh_todo_list(player)
    
    elseif string.match(element.name, "^toggle_section_(.+)$") then
        local section_id = string.match(element.name, "^toggle_section_(.+)$")
        GoalsManager.toggle_section_visibility(player, section_id)
    end
end)

-- Handle text input (Enter key in textfield)
script.on_event(defines.events.on_gui_confirmed, function(event)
    local player = game.get_player(event.player_index)
    local element = event.element
    
    if element.name == "todo_input" then
        TodoManager.add_todo(player, element.text, GuiManager.refresh_todo_list_for_all_players)
        element.text = ""
    end
end)

-- Initialize buttons for existing players when mod is added
script.on_load(function()
    for _, player in pairs(game.players) do
        if player.connected then
            GuiManager.create_todo_button(player)
        end
    end
end)