local mod_gui = require("__core__.lualib.mod-gui")

-- Initialize storage on game start
script.on_init(function()
    storage.todos = {}
    storage.next_todo_id = 1
end)

-- Handle configuration changes (mod updates, etc.)
script.on_configuration_changed(function()
    if not storage.todos then
        storage.todos = {}
    end
    if not storage.next_todo_id then
        storage.next_todo_id = 1
    end
    -- Add order field to existing todos if missing
    for i, todo in ipairs(storage.todos) do
        if not todo.order then
            todo.order = i
        end
    end
end)

-- Create the toggle button for each player
local function create_todo_button(player)
    local button_flow = mod_gui.get_button_flow(player)
    if not button_flow.todo_button then
        button_flow.add{
            type = "sprite-button",
            name = "todo_button",
            sprite = "utility/logistic_network_panel_black",
            tooltip = {"gui.todo-button-tooltip"}
        }
    end
end

-- Remove the toggle button
local function destroy_todo_button(player)
    local button_flow = mod_gui.get_button_flow(player)
    if button_flow.todo_button then
        button_flow.todo_button.destroy()
    end
end

-- Create the main todo window
local function create_todo_window(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if frame_flow.todo_window then
        return frame_flow.todo_window
    end
    
    local window = frame_flow.add{
        type = "frame",
        name = "todo_window",
        direction = "vertical",
        caption = {"gui.todo-window-title"}
    }
    
    -- Add input section
    local input_flow = window.add{
        type = "flow",
        name = "input_flow",
        direction = "horizontal"
    }
    
    input_flow.add{
        type = "textfield",
        name = "todo_input",
        text = "",
        tooltip = {"gui.todo-add-placeholder"}
    }
    
    input_flow.add{
        type = "button",
        name = "add_todo_button",
        caption = {"gui.todo-add-button"}
    }
    
    -- Add todo list container
    local list_scroll = window.add{
        type = "scroll-pane",
        name = "todo_scroll",
        horizontal_scroll_policy = "never",
        vertical_scroll_policy = "auto"
    }
    list_scroll.style.maximal_height = 400
    list_scroll.style.minimal_width = 400
    
    local todo_list = list_scroll.add{
        type = "flow",
        name = "todo_list",
        direction = "vertical"
    }
    
    -- Add controls section
    local controls_flow = window.add{
        type = "flow",
        name = "controls_flow",
        direction = "horizontal"
    }
    
    controls_flow.add{
        type = "button",
        name = "clear_completed_button",
        caption = {"gui.todo-clear-completed"}
    }
    
    return window
end

-- Destroy the todo window
local function destroy_todo_window(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if frame_flow.todo_window then
        frame_flow.todo_window.destroy()
    end
end

-- Refresh the todo list display for all players
local function refresh_todo_list_for_all_players()
    for _, player in pairs(game.connected_players) do
        local frame_flow = mod_gui.get_frame_flow(player)
        if frame_flow.todo_window then
            refresh_todo_list(player)
        end
    end
end

-- Refresh the todo list for a specific player
function refresh_todo_list(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if not frame_flow.todo_window then return end
    
    local todo_list = frame_flow.todo_window.todo_scroll.todo_list
    todo_list.clear()
    
    if #storage.todos == 0 then
        todo_list.add{
            type = "label",
            caption = {"gui.todo-empty-message"},
            style = "description_label"
        }
        return
    end
    
    -- Sort todos by order field
    table.sort(storage.todos, function(a, b) return a.order < b.order end)
    
    for i, todo in ipairs(storage.todos) do
        local todo_flow = todo_list.add{
            type = "flow",
            name = "todo_" .. todo.id,
            direction = "horizontal"
        }
        
        -- Checkbox
        todo_flow.add{
            type = "checkbox",
            name = "todo_checkbox_" .. todo.id,
            state = todo.completed,
            tooltip = "Toggle completion"
        }
        
        -- Todo text with owner info
        local text_style = todo.completed and "disabled_label" or "label"
        local display_text = "[" .. todo.owner .. "] " .. todo.text
        todo_flow.add{
            type = "label",
            caption = display_text,
            style = text_style
        }
        
        -- Reorder buttons
        local reorder_flow = todo_flow.add{
            type = "flow",
            name = "reorder_flow_" .. todo.id,
            direction = "vertical"
        }
        
        local move_up = reorder_flow.add{
            type = "sprite-button",
            name = "move_up_" .. todo.id,
            sprite = "utility/arrow_button_up",
            tooltip = {"gui.todo-move-up"}
        }
        move_up.style.width = 20
        move_up.style.height = 20
        
        local move_down = reorder_flow.add{
            type = "sprite-button",
            name = "move_down_" .. todo.id,
            sprite = "utility/arrow_button_down",
            tooltip = {"gui.todo-move-down"}
        }
        move_down.style.width = 20
        move_down.style.height = 20
        
        -- Disable buttons for first/last items
        if i == 1 then
            move_up.enabled = false
        end
        if i == #storage.todos then
            move_down.enabled = false
        end
        
        -- Delete button (only show for owner)
        if todo.owner == player.name then
            local delete_button = todo_flow.add{
                type = "sprite-button",
                name = "delete_todo_" .. todo.id,
                sprite = "utility/trash",
                tooltip = "Delete todo"
            }
            delete_button.style.width = 24
            delete_button.style.height = 24
        end
    end
end

-- Add a new todo
local function add_todo(player, text)
    if text == "" then return end
    
    local new_todo = {
        id = storage.next_todo_id,
        text = text,
        completed = false,
        owner = player.name,
        created = game.tick,
        order = #storage.todos + 1
    }
    
    table.insert(storage.todos, new_todo)
    storage.next_todo_id = storage.next_todo_id + 1
    
    refresh_todo_list_for_all_players()
end

-- Toggle todo completion
local function toggle_todo(todo_id)
    for _, todo in pairs(storage.todos) do
        if todo.id == todo_id then
            todo.completed = not todo.completed
            break
        end
    end
    refresh_todo_list_for_all_players()
end

-- Delete a todo
local function delete_todo(todo_id, player)
    for i, todo in pairs(storage.todos) do
        if todo.id == todo_id then
            if todo.owner == player.name then
                table.remove(storage.todos, i)
                refresh_todo_list_for_all_players()
            end
            break
        end
    end
end

-- Clear completed todos
local function clear_completed_todos()
    local new_todos = {}
    for _, todo in pairs(storage.todos) do
        if not todo.completed then
            table.insert(new_todos, todo)
        end
    end
    storage.todos = new_todos
    -- Reorder remaining todos
    for i, todo in ipairs(storage.todos) do
        todo.order = i
    end
    refresh_todo_list_for_all_players()
end

-- Move todo up in order
local function move_todo_up(todo_id)
    table.sort(storage.todos, function(a, b) return a.order < b.order end)
    
    for i, todo in ipairs(storage.todos) do
        if todo.id == todo_id and i > 1 then
            -- Swap order values
            local temp_order = storage.todos[i-1].order
            storage.todos[i-1].order = todo.order
            todo.order = temp_order
            
            refresh_todo_list_for_all_players()
            break
        end
    end
end

-- Move todo down in order
local function move_todo_down(todo_id)
    table.sort(storage.todos, function(a, b) return a.order < b.order end)
    
    for i, todo in ipairs(storage.todos) do
        if todo.id == todo_id and i < #storage.todos then
            -- Swap order values
            local temp_order = storage.todos[i+1].order
            storage.todos[i+1].order = todo.order
            todo.order = temp_order
            
            refresh_todo_list_for_all_players()
            break
        end
    end
end

-- Handle player joining
script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.get_player(event.player_index)
    create_todo_button(player)
end)

-- Handle GUI clicks
script.on_event(defines.events.on_gui_click, function(event)
    local player = game.get_player(event.player_index)
    local element = event.element
    
    if element.name == "todo_button" then
        local frame_flow = mod_gui.get_frame_flow(player)
        if frame_flow.todo_window then
            destroy_todo_window(player)
        else
            create_todo_window(player)
            refresh_todo_list(player)
        end
    
    elseif element.name == "add_todo_button" then
        local frame_flow = mod_gui.get_frame_flow(player)
        if frame_flow.todo_window then
            local input = frame_flow.todo_window.input_flow.todo_input
            add_todo(player, input.text)
            input.text = ""
        end
    
    elseif element.name == "clear_completed_button" then
        clear_completed_todos()
    
    elseif string.match(element.name, "^todo_checkbox_(%d+)$") then
        local todo_id = tonumber(string.match(element.name, "^todo_checkbox_(%d+)$"))
        toggle_todo(todo_id)
    
    elseif string.match(element.name, "^delete_todo_(%d+)$") then
        local todo_id = tonumber(string.match(element.name, "^delete_todo_(%d+)$"))
        delete_todo(todo_id, player)
    
    elseif string.match(element.name, "^move_up_(%d+)$") then
        local todo_id = tonumber(string.match(element.name, "^move_up_(%d+)$"))
        move_todo_up(todo_id)
    
    elseif string.match(element.name, "^move_down_(%d+)$") then
        local todo_id = tonumber(string.match(element.name, "^move_down_(%d+)$"))
        move_todo_down(todo_id)
    end
end)

-- Handle text input (Enter key in textfield)
script.on_event(defines.events.on_gui_confirmed, function(event)
    local player = game.get_player(event.player_index)
    local element = event.element
    
    if element.name == "todo_input" then
        add_todo(player, element.text)
        element.text = ""
    end
end)

-- Initialize buttons for existing players when mod is added
script.on_load(function()
    for _, player in pairs(game.players) do
        if player.connected then
            create_todo_button(player)
        end
    end
end)